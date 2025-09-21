import express from "express"; 
import { conn } from "../dbconnect";
import { ResultSetHeader } from "mysql2";

export const router = express.Router(); // สร้าง route

// อัพเดต balance ยอดเงินของผู้ใช้
router.put("/update-balance", (req, res) => { 
  const { userId, amount } = req.body; //ดึงข้อมูล userId และ amount จาก body ของ request

  if (!userId || !amount) { // ตรวจสอบว่าส่งข้อมูลครบไหม
    return res.status(400).json({ success: false, message: "ข้อมูลไม่ครบ" });
  }

  // SQL: หัก balance
  const sql = "UPDATE customer SET balance = balance - ? WHERE idx = ?"; //อัพเดตข้อมูล customer เอา ยอดเงิน - ค่าที่ส่งเข้ามา อัพเดตฌฉพาะคนที่ idx ตรงกับค่าที่ส่งมา

  conn.query(sql, [amount, userId], (/*จะถูกเรียกเมื่อคำสั่ง SQL ทำงานเสร็จ */err, result: ResultSetHeader /*จำนวนแถวที่ถูกแก้ */) => { // ? จะถูกแทนค่าโดย amount
    if (err) { // ถ้าเกิด ข้อผิดพลาดจากฐานข้อมูล
      console.error("DB ERROR:", err);
      return res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในระบบ" });
    }

    if (result.affectedRows === 0) { //ตรวจสอบว่า SQL อัพเดตแถวไหม
      return res.status(404).json({ success: false, message: "ไม่พบผู้ใช้" });
    }

    res.json({ success: true, message: "หักเงินสำเร็จ" });// ส่ง JSON กลับไปว่า หักเงินสำเร็จ
  });
});
