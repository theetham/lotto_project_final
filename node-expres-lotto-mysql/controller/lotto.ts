import express from "express";
import { conn } from "../dbconnect";
import { ResultSetHeader } from "mysql2";

export const router = express.Router();

// Middleware สำคัญ ต้องมีใน main app.ts ด้วย: app.use(express.json());

// ทดสอบ API
router.get("/", (req, res) => {
  res.send("API Lotto route OK ✅");
});

// ดึงข้อมูลล็อตโต้ทั้งหมด
router.get("/all", (req, res) => {
  const sql = "SELECT * FROM lotto_name";  // เปลี่ยนชื่อ table เป็น lotto_name
  conn.query(sql, (err, results: any) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในระบบ" });
    }
    res.json({
      success: true,
      data: results,
    });
  });
});

// ลบข้อมูลล็อตโต้ทั้งหมด
router.delete("/delete", (req, res) => {
  const sql = "DELETE FROM lotto_name";  // ลบข้อมูลทั้งหมด

  conn.query(sql, (err, results: any) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: `ไม่สามารถลบข้อมูลได้: ${err.message}` });
    }

    res.json({
      success: true,
      message: `ลบข้อมูลล็อตโต้ทั้งหมดเรียบร้อยแล้ว (${results.affectedRows} แถว)`,
    });
  });
});

// เพิ่มเลขล็อตโต้หลายตัวพร้อมกัน
router.post("/insert", (req, res) => {
  const numbers: {lottoID: number, number: string}[] = req.body.numbers;

  // ตรวจสอบข้อมูลที่ส่งมา
  if (!numbers || !Array.isArray(numbers) || numbers.length === 0) {
    return res.status(400).json({ success: false, message: "ไม่มีเลขที่ส่งมา" });
  }

  // map ตัวเลข => [lottoID, number, status]
  const values = numbers.map(num => [num.lottoID, num.number, 0]); // status เริ่มต้น = 0

  const sql = "INSERT INTO lotto_name (lottoID, number, status) VALUES ?";

  conn.query(sql, [values], (err, results: any) => {
    if (err) {
      console.error("DB ERROR:", err);
      // แสดงข้อความผิดพลาดจากการ query
      return res.status(500).json({ success: false, message: `เพิ่มข้อมูลไม่สำเร็จ: ${err.message}` });
    }
    res.json({
      success: true,
      message: "เพิ่มข้อมูลสำเร็จ",
      inserted: results.affectedRows,
    });
  });
});


// ดึงข้อมูลสมาชิกตาม id (userId)
router.get("/customer/:userId", (req, res) => {
  const userId = req.params.userId; // ดึง userId จาก params
  const sql = "SELECT fullname, phone, balance,role FROM customer WHERE idx = ?";  // ใช้ idx แทน id

  conn.query(sql, [userId], (err, results: any) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในระบบ" });
    }

    if (results.length === 0) {
      return res.status(404).json({ success: false, message: "ไม่พบข้อมูลสมาชิก" });
    }

    res.json({
      success: true,
      data: results[0], // ส่งข้อมูลสมาชิกกลับ
    });
  });
});


// เพิ่ม route สำหรับอัพเดต status ของเลขล็อตโต้ที่เลือก
router.put("/update-status", (req, res) => {
  const selectedNumbers = req.body.selectedNumbers; // รับหมายเลขล็อตโต้ที่เลือกจาก client
  if (!selectedNumbers || selectedNumbers.length === 0) {
    return res.status(400).json({ success: false, message: "กรุณาระบุหมายเลขล็อตโต้ที่เลือก" });
  }

  const updatePromises = selectedNumbers.map((number: any) => {
    const sql = "UPDATE lotto_name SET status = 1 WHERE number = ?"; // สั่งให้ status เปลี่ยนเป็น 1 สำหรับหมายเลขที่เลือก
    return new Promise((resolve, reject) => {
      conn.query(sql, [number], (err, result) => {
        if (err) {
          reject(err); // ถ้ามีข้อผิดพลาดให้ reject
        } else {
          resolve(result); // ถ้าทำสำเร็จให้ resolve
        }
      });
    });
  });

  // รอให้การอัพเดตเสร็จสิ้น
  Promise.all(updatePromises)
    .then(() => {
      res.json({ success: true, message: "อัพเดตสถานะเรียบร้อย" });
    })
    .catch((err) => {
      console.error("Error updating status:", err);
      res.status(500).json({ success: false, message: "ไม่สามารถอัพเดตสถานะได้" });
    });
});

// เพิ่ม route สำหรับอัพเดต owner และ status ของเลขล็อตโต้ที่เลือก
router.put("/update-owner", (req, res) => {
  const selectedNumbers = req.body.selectedNumbers; // รับหมายเลขล็อตโต้ที่เลือกจาก client
  const userId = req.body.userId; // รับ userId จาก request
  const status = req.body.status; // รับ status จาก request

  if (!selectedNumbers || selectedNumbers.length === 0 || !userId || status === undefined) {
    return res.status(400).json({ success: false, message: "กรุณาระบุหมายเลขล็อตโต้ที่เลือกและ userId และ status" });
  }

  const updatePromises = selectedNumbers.map((number: any) => {
    const sql = "UPDATE lotto_name SET owner = ?, status = ? WHERE number = ?"; // อัพเดต owner และ status
    return new Promise((resolve, reject) => {
      conn.query(sql, [userId, status, number], (err, result) => {
        if (err) {
          reject(err); // ถ้ามีข้อผิดพลาดให้ reject
        } else {
          resolve(result); // ถ้าทำสำเร็จให้ resolve
        }
      });
    });
  });

  // รอให้การอัพเดตเสร็จสิ้น
  Promise.all(updatePromises)
    .then(() => {
      res.json({ success: true, message: "อัพเดตเจ้าของเลขล็อตโต้และสถานะเรียบร้อย" });
    })
    .catch((err) => {
      console.error("Error updating owner and status:", err);
      res.status(500).json({ success: false, message: "ไม่สามารถอัพเดตเจ้าของเลขล็อตโต้และสถานะได้" });
    });
});

router.get("/buy_al", (req, res) => {
  const userId = req.query.userId; // รับ userId จาก query parameter
  const sql = "SELECT * FROM lotto_name WHERE owner = ?";  // กรองเฉพาะที่ owner ตรงกับ userId
  
  conn.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในระบบ" });
    }
    
    // ส่งข้อมูลที่กรองมาแล้วกลับไป
    res.json({
      success: true,
      data: results,
    });
  });
});



router.post("/draw", (req, res) => {
  const deleteSql = "DELETE FROM lotto_winner";
  conn.query(deleteSql, (delErr) => {
    if (delErr) {
      console.error("Delete error:", delErr);
      return res.status(500).json({ success: false, message: "ลบข้อมูลเดิมไม่สำเร็จ" });
    }

    const getAllSql = "SELECT number, lottoID FROM lotto_name"; // ดึงเลขและ lottoID
    conn.query(getAllSql, (getErr, allResults: any[]) => {
      if (getErr) {
        console.error("Fetch error:", getErr);
        return res.status(500).json({ success: false, message: "ดึงข้อมูลทั้งหมดไม่สำเร็จ" });
      }

      if (allResults.length === 0) {
        return res.status(400).json({ success: false, message: "ไม่มีเลขล็อตโต้ให้สุ่ม" });
      }

      function pickRandom(arr: any[], n: number): any[] {
        const shuffled = [...arr].sort(() => 0.5 - Math.random());
        return shuffled.slice(0, n);
      }

      function toSixDigit(num: string | number): string {
        return String(num).padStart(6, '0');
      }

      const sixDigitNumbers = allResults.filter(r => String(r.number).length === 6);

      if (sixDigitNumbers.length < 3) {
        return res.status(400).json({ success: false, message: "เลข 6 หลักไม่พอสำหรับสุ่ม 3 รางวัล" });
      }

      // ✅ สุ่มรางวัลที่ 1-3
      const threeSix = pickRandom(sixDigitNumbers, 3);
      const set1 = [toSixDigit(threeSix[0].number)];
      const set2 = [toSixDigit(threeSix[1].number)];
      const set3 = [toSixDigit(threeSix[2].number)];
      const set1LottoID = threeSix[0].lottoID;
      const set2LottoID = threeSix[1].lottoID;
      const set3LottoID = threeSix[2].lottoID;

      // ✅ รางวัลเลขท้าย 3 ตัว = 3 ตัวท้ายของรางวัลที่ 1
      const last3FromSet1 = String(set1[0]).slice(-3); 
      const set4 = [last3FromSet1];

      // ✅ เลขท้าย 2 ตัว = สุ่ม 0–99
      const randomLast2 = Math.floor(Math.random() * 100);
      const last2Str = String(randomLast2).padStart(2, "0"); // ทำให้เป็น 2 หลัก เช่น 5 => "05"
      const set5 = [last2Str];

      // ✅ หา lottoID ที่มีเลขท้าย 2 ตัว ตรงกับที่สุ่มได้
      const matchedLast2 = allResults.find(entry => {
        const numStr = toSixDigit(entry.number);
        return numStr.slice(-2) === last2Str;
      });

      const last2LottoID = matchedLast2 ? matchedLast2.lottoID : null;

      // ✅ เตรียมข้อมูลสำหรับบันทึก (เพิ่ม type และ prize_amount ในแต่ละแถว)
      const numbersToInsert = [
        [set1[0], set1LottoID, "รางวัลที่ 1", 6000000],
        [set2[0], set2LottoID, "รางวัลที่ 2", 500000],
        [set3[0], set3LottoID, "รางวัลที่ 3", 100000],
        [set4[0], null, "รางวัลเลขท้าย 3 ตัว", 5000],
        [set5[0], last2LottoID, "รางวัลเลขท้าย 2 ตัว", 2000]
      ];

      const insertSql = "INSERT INTO lotto_winner (number, lottoID, type, prize_amount) VALUES ?";
      conn.query(insertSql, [numbersToInsert], (insErr, insertRes: ResultSetHeader) => {
        if (insErr) {
          console.error("Insert error:", insErr);
          return res.status(500).json({ success: false, message: "บันทึกผลไม่สำเร็จ" });
        }

        res.json({
          success: true,
          winners: {
            "1": set1,
            "2": set2,
            "3": set3,
            "last3": set4,
            "last2": set5,
            "last2_lottoID": last2LottoID ?? "ไม่พบ"
          },
          count: insertRes.affectedRows
        });
      });
    });
  });
});




router.get("/winner", (req, res) => {
  const sql = "SELECT number FROM lotto_winner";
  conn.query(sql, (err, results: any[]) => {
    if (err) {
      console.error("Error:", err);
      return res.status(500).json({ success: false, message: "ดึงข้อมูลไม่สำเร็จ" });
    }

    if (!results || results.length === 0) {
      return res.json({ success: true, winners: {} });
    }

    // สมมุติว่า index 0-2 = รางวัลที่ 1-3, 3 = เลขท้าย 3 ตัว, 4 = เลขท้าย 2 ตัว
    const winners = {
      "1": [results[0]?.number ?? ""],
      "2": [results[1]?.number ?? ""],
      "3": [results[2]?.number ?? ""],
      "last3": [results[3]?.number ?? ""],
      "last2": [results[4]?.number ?? ""],
    };

    res.json({ success: true, winners });
  });
});


// ลบลูกค้าทั้งหมดที่มี role = 'customer'
router.delete("/reset-customer", (req, res) => {
  const sql = "DELETE FROM customer WHERE role = 'customer'";

  conn.query(sql, (err, results: any) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: "ไม่สามารถลบลูกค้าได้" });
    }

    res.json({
      success: true,
      message: `ลบลูกค้าที่เป็น customer สำเร็จแล้ว (${results.affectedRows} รายการ)`,
    });
  });
});


router.get("/check-prize", (req, res) => {
  const userId = req.query.userId;
  if (!userId) {
    return res.status(400).json({ success: false, message: "userId is required" });
  }

  // ดึงเลขล็อตโต้ของ user พร้อม join กับตาราง lotto_winner เพื่อเอา type รางวัล (ถ้ามี)
  const sql = `
    SELECT ln.lottoID, ln.number, lw.type
    FROM lotto_name ln
    LEFT JOIN lotto_winner lw ON ln.lottoID = lw.lottoID
    WHERE ln.owner = ?
  `;

  conn.query(sql, [userId], (err, results: any[]) => {
    if (err) {
      console.error("DB error fetching user lotto with prize type:", err);
      return res.status(500).json({ success: false, message: "ไม่สามารถดึงข้อมูลล็อตโต้ผู้ใช้ได้" });
    }

    // map ผลลัพธ์พร้อม flag ว่าถูกรางวัลไหม (ถ้า type != null = ถูกรางวัล)
    const data = results.map((item: { lottoID: any; number: any; type: null; }) => ({
      lottoID: item.lottoID,
      number: item.number,
      isWinner: item.type !== null,
      type: item.type, // ส่ง type กลับไปเลย
    }));

    res.json({ success: true, data });
  });
});


// เพิ่ม API สำหรับการลบหมายเลขล็อตโต้ที่ขึ้นเงินแล้ว
router.delete("/claim-prize", (req, res) => {
  const { userId, lottoID, prizeAmount } = req.body;

  if (!userId || !lottoID || !prizeAmount) {
    return res.status(400).json({ success: false, message: "ข้อมูลไม่ครบถ้วน" });
  }

  // อัพเดตยอดเงินในบัญชีผู้ใช้
  const updateBalanceSql = "UPDATE customer SET balance = balance + ? WHERE idx = ?";
  conn.query(updateBalanceSql, [prizeAmount, userId], (err, result) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: "ไม่สามารถอัพเดตยอดเงินได้" });
    }

    // ลบหมายเลขล็อตโต้ที่ถูกรางวัลแล้ว
    const deleteLottoSql = "DELETE FROM lotto_name WHERE lottoID = ?";
    conn.query(deleteLottoSql, [lottoID], (deleteErr) => {
      if (deleteErr) {
        console.error("DB ERROR:", deleteErr);
        return res.status(500).json({ success: false, message: "ไม่สามารถลบหมายเลขล็อตโต้ได้" });
      }

      res.json({ success: true, message: "ขึ้นเงินสำเร็จและลบหมายเลขล็อตโต้แล้ว" });
    });
  });
});




















