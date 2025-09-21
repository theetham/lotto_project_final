import express from "express";
import { conn } from "../dbconnect";

export const router = express.Router();

// router.get("/", async (req, res) => {
//   const [rows] = await conn.query("SELECT * FROM customer");
//   res.send(rows);
// });
router.get("/", (req, res) => {
  res.send("API Register route OK ✅");
});

router.post("/", (req, res) => {
  const { fullname, phone, image, password, role, balance } = req.body;

  if (!fullname || !phone || !password || !role || !balance) {
    return res
      .status(400)
      .json({ success: false, message: "กรอกข้อมูลไม่ครบ" });      
  }
  // SQL INSERT
  const sql =
    "INSERT INTO customer (fullname, phone, image, password, role, balance) VALUES (?, ?, ?, ?, ?, ?)";
  conn.query(
    sql,
    [fullname, phone, image, password, role, balance],
    (err, result) => {
      if (err) {
        console.error("DB ERROR:", err);
        return res.status(500).json({
          success: false,
          message: "บันทึกข้อมูลไม่สำเร็จ",
          error: err,
        });
      }
      return res.json({ success: true, message: "สมัครสมาชิกสำเร็จ" });
    }
  );
});
