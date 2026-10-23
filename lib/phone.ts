export function normalizePhone(value:string){return value.replace(/[০-৯]/g,c=>String(c.charCodeAt(0)-2534)).replace(/[\s()-]/g,'').replace(/^\+?88(?=01)/,'')}
