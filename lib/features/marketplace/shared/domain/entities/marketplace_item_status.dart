/// How a seller's listing stands on the market:
/// - [live]: active (`is_active`) and in stock (`stock_quantity > 0`)
/// - [hidden]: hidden by the seller (`!is_active`)
/// - [removed]: removed by an admin (`removed_at != null`)
/// - [outOfStock]: active (`is_active`) with zero stock (`stock_quantity <= 0`)
enum MarketplaceItemStatus { live, hidden, removed, outOfStock }
