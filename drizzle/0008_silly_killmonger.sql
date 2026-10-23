ALTER TABLE `order_items` ADD `unit_weight_grams` integer;--> statement-breakpoint
ALTER TABLE `orders` ADD `discount` integer DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `weight_grams` integer;
--> statement-breakpoint
CREATE TRIGGER validate_discount_update BEFORE UPDATE OF total,discount ON orders BEGIN
 SELECT CASE WHEN NEW.discount<0 OR NEW.discount>NEW.subtotal OR NEW.total<>NEW.subtotal+NEW.shipping-NEW.discount THEN RAISE(ABORT,'invalid discount total') END;
 SELECT CASE WHEN NEW.status NOT IN ('Cancelled','Returned') AND NEW.total<COALESCE((SELECT SUM(CASE WHEN kind='Refund' THEN -amount ELSE amount END) FROM payments WHERE order_id=NEW.id),0) THEN RAISE(ABORT,'refund excess receipts before reducing total') END;
END;
--> statement-breakpoint
DROP TRIGGER packing_insert_guard;
--> statement-breakpoint
DROP TRIGGER packing_update_guard;
--> statement-breakpoint
CREATE TRIGGER packing_insert_guard BEFORE INSERT ON packing_checks WHEN (SELECT status FROM orders WHERE id=NEW.order_id) NOT IN ('Confirmed','Processing','Packed','Ready to Ship') BEGIN SELECT RAISE(ABORT,'packing closed'); END;
--> statement-breakpoint
CREATE TRIGGER packing_update_guard BEFORE UPDATE ON packing_checks WHEN (SELECT status FROM orders WHERE id=NEW.order_id) NOT IN ('Confirmed','Processing','Packed','Ready to Ship') BEGIN SELECT RAISE(ABORT,'packing closed'); END;
--> statement-breakpoint
CREATE TRIGGER require_ready_checks BEFORE UPDATE OF status ON orders WHEN NEW.status IN ('Ready to Ship','In-Transit') AND NEW.status<>OLD.status BEGIN
 SELECT CASE WHEN NEW.weight_grams IS NULL OR NEW.weight_grams<=0 OR EXISTS(SELECT 1 FROM order_items WHERE order_id=NEW.id AND COALESCE(unit_weight_grams,0)<=0) THEN RAISE(ABORT,'product weights required') END;
 SELECT CASE WHEN EXISTS(SELECT 1 FROM order_items i LEFT JOIN packing_checks p ON p.item_id=i.id WHERE i.order_id=NEW.id AND COALESCE(p.checked,0)=0) THEN RAISE(ABORT,'packing checklist incomplete') END;
END;
