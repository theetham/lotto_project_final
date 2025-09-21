// import { createPool } from "mysql2/promise";
// export const conn = createPool({
//   connectionLimit: 10,
//   host: "202.28.34.203",
//   user: "mb68_66011212143",
//   password: "dyj4Jtzuk9sA",
//   database: "mb68_66011212143",
// });
import mysql, { Connection } from "mysql2";

export const conn: Connection = mysql.createConnection({
  host: "202.28.34.203",
  user: "mb68_66011212143",
  password: "dyj4Jtzuk9sA",
  database: "mb68_66011212143",
});
