import express from "express";
import { router as login } from "./controller/login";
import { router as register } from "./controller/register";
import { router as lotto } from "./controller/lotto";  // เพิ่มบรรทัดนี้


import { router as balance} from "./controller/balance"; // ตั้งชื่อเป็น balance


import bodyParser from "body-parser";
import cors from "cors";

export const app = express();

app.use(bodyParser.json());
app.use(cors());
app.use("/login", login);
// app.use("/customer", customer);
app.use("/register", register);
app.use("/api/lotto", lotto);   // เพิ่มบรรทัดนี้ เพื่อให้ API lotto ใช้งานได้ที่ /api/lotto

app.use("/api/user", balance); //  route เรียกมาจากไฟล์ balance.ts