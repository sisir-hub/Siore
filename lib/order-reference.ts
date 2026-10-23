export const DISPLAY_ID="CASE WHEN n.number IS NULL THEN o.id ELSE 'SIO-'||printf('%06d',n.number) END";
export async function displayId(db:any,id:string){const n:any=await db.prepare('SELECT number FROM order_numbers WHERE order_id=?').bind(id).first();return n?'SIO-'+String(n.number).padStart(6,'0'):id}
