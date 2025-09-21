import express from "express";
import { conn } from "../dbconnect";

export const router = express.Router();

router.get("/", (req, res) => {
  res.send("API Login route OK ✅");
});

router.post("/", (req, res) => {
  const { phone, password } = req.body;

  if (!phone || !password) {
    return res
      .status(400)
      .json({ success: false, message: "กรอกข้อมูลไม่ครบ" });
  }

  const sql = "SELECT * FROM customer WHERE phone = ? AND password = ?";
  conn.query(sql, [phone, password], (err, results: any) => {
    if (err) {
      console.error("DB ERROR:", err);
      return res
        .status(500)
        .json({ success: false, message: "เกิดข้อผิดพลาดในระบบ" });
    }

    if (results.length > 0) {
      const user = results[0];
      return res.json({
        success: true,
        message: "เข้าสู่ระบบสำเร็จ",
        user: {
          id: user.id,
          idx: user.idx,
          fullname: user.fullname,
          phone: user.phone,
          role: user.role,
        },
      });
    } else {
      return res.json({
        success: false,
        message: "เบอร์โทรหรือรหัสผ่านไม่ถูกต้อง",
      });
    }
  });
});
