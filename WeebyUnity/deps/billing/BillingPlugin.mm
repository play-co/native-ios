#import "BillingPlugin.h"

// TODO: Verify store receipt for security

@implementation BillingPlugin

- (void) dealloc {
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];

	self.purchases = nil;
	self.bundleID = nil;

	[super dealloc];
}

- (id) init {
	self = [super init];
	if (!self) {
		return nil;
	}

	self.purchases = [NSMutableDictionary dictionary];

	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];

	self.bundleID = @"unknown.bundle";

	return self;
}

- (void) completeTransaction:(SKPaymentTransaction *)transaction {
	NSString *sku = transaction.payment.productIdentifier;
	NSString *token = transaction.transactionIdentifier;

	if ([self.purchases objectForKey:token] != nil) {
		NSLog(@"{billing} WARNING: Strangeness is afoot.  The same purchase token was specified twice");
	}

	// Remember transaction so that it can be consumed later
	[self.purchases setObject:transaction forKey:token];

	// Strip bundleID prefix
	if ([sku hasPrefix:self.bundleID]) {
		sku = [sku substringFromIndex:([self.bundleID length] + 1)];
	}

	[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
										  @"billingPurchase",@"name",
										  sku, @"sku",
										  token, @"token",
										  [NSNull null], @"failure",
										  nil]];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction {
	NSString *sku = transaction.payment.productIdentifier;

	// Strip bundleID prefix
	if ([sku hasPrefix:self.bundleID]) {
		sku = [sku substringFromIndex:([self.bundleID length] + 1)];
	}

	// Generate error code string
	NSString *errorCode = @"failed";
	switch (transaction.error.code) {
		case SKErrorClientInvalid:
			errorCode = @"client invalid";
			break;
		case SKErrorPaymentCancelled:
			errorCode = @"cancel";
			break;
		case SKErrorPaymentInvalid:
			errorCode = @"payment invalid";
			break;
		case SKErrorPaymentNotAllowed:
			errorCode = @"payment not allowed";
			break;
		case SKErrorStoreProductNotAvailable:
			errorCode = @"item unavailable";
			break;
	}

	[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
										  @"billingPurchase",@"name",
										  sku,@"sku",
										  [NSNull null],@"token",
										  errorCode,@"failure",
										  nil]];

    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	NSLog(@"{billing} Got products response with %d hits and %d misses", (int)response.products.count, (int)response.invalidProductIdentifiers.count);

	bool success = false;
	NSString *sku = nil;

	NSArray *products = response.products;
	if (products.count > 0) {
		SKProduct *product = [products objectAtIndex:0];

		if (product) {
			NSLog(@"{billing} Found product id=%@, title=%@", product.productIdentifier, product.localizedTitle);

			SKPayment *payment =  [SKPayment paymentWithProduct:product];
			[[SKPaymentQueue defaultQueue] addPayment:payment];

			success = true;
		}
	}

	for (NSString *invalidProductId in response.invalidProductIdentifiers) {
		NSLog(@"{billing} Unused product id: %@", invalidProductId);

		sku = invalidProductId;
	}

	if (!success) {
		// Strip bundleID prefix
		if (sku != nil && [sku hasPrefix:self.bundleID]) {
			sku = [sku substringFromIndex:([self.bundleID length] + 1)];
		}

		[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
											  @"billingPurchase",@"name",
											  (sku == nil ? [NSNull null] : sku),@"sku",
											  [NSNull null],@"token",
											  @"invalid product",@"failure",
											  nil]];
	}
}

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		NSString *sku = transaction.payment.productIdentifier;
		NSString *token = transaction.transactionIdentifier;

		switch (transaction.transactionState) {
			case SKPaymentTransactionStatePurchased:
				NSLog(@"{billing} Transaction completed purchase for sku=%@ and token=%@", sku, token);
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				NSLog(@"{billing} Ignoring restored transaction for sku=%@ and token=%@", sku, token);
				[[SKPaymentQueue defaultQueue] finishTransaction: transaction];
				break;
			case SKPaymentTransactionStatePurchasing:
				NSLog(@"{billing} Transaction purchasing for sku=%@ and token=%@", sku, token);
				break;
			case SKPaymentTransactionStateFailed:
				NSLog(@"{billing} Transaction failed with error code %d(%@) for sku=%@ and token=%@", (int)transaction.error.code, transaction.error.localizedDescription, sku, token);
				[self failedTransaction:transaction];
				break;
			default:
				NSLog(@"{billing} Ignoring unknown transaction state %d: error=%d for sku=%@ and token=%@", transaction.transactionState, (int)transaction.error.code, sku, token);
				break;
		}
	}
}

- (void) requestPurchase:(NSString *)productIdentifier {
	// This is done exclusively to set up an SKPayment object with the result (it will initiate a purchase)

	NSString *bundledProductId = [self.bundleID stringByAppendingFormat:@".%@", productIdentifier];

	// Create a set with the given identifier
	NSSet *productIdentifiers = [NSSet setWithObjects:productIdentifier,bundledProductId,nil];

	// Create a products request
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
	productsRequest.delegate = self;

	// Kick it off!
	[productsRequest start];
}

- (void) initializeWithManifest:(NSDictionary *)manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
	@try {
		NSDictionary *ios = [manifest valueForKey:@"ios"];
		NSString *bundleID = [ios valueForKey:@"bundleID"];

		self.bundleID = bundleID;

		NSLog(@"{billing} Initialized with manifest bundleID: '%@'", bundleID);
		
	}
	@catch (NSException *exception) {
		NSLog(@"{billing} Failure to get ios:bundleID from manifest file: %@", exception);
	}
}

- (void) isConnected:(NSDictionary *)jsonObject {
	BOOL isMarketAvailable = [SKPaymentQueue canMakePayments];

	NSLog(@"{billing} Responded with Market Available: %@", isMarketAvailable ? @"YES" : @"NO");

	[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
										  @"billingConnected",@"name",
										  (isMarketAvailable ? kCFBooleanTrue : kCFBooleanFalse), @"connected",
										  nil]];
}

- (void) purchase:(NSDictionary *)jsonObject {
	NSString *sku = nil;

	@try {
		sku = [jsonObject valueForKey:@"sku"];

		[self requestPurchase:sku];
	}
	@catch (NSException *exception) {
		NSLog(@"{billing} WARNING: Unable to purchase item: %@", exception);

		[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
											  @"billingPurchase",@"name",
											  sku ? sku : [NSNull null],@"sku",
											  [NSNull null],@"token",
											  @"failed",@"failure",
											  nil]];
	}
}

- (void) consume:(NSDictionary *)jsonObject {
	NSString *token = nil;

	@try {
		token = [jsonObject valueForKey:@"token"];

		SKPaymentTransaction *transaction = [self.purchases valueForKey:token];
		if (!transaction) {
			NSLog(@"{billing} Failure consuming item with unknown token: %@", token);

			[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
												  @"billingConsume",@"name",
												  token,@"token",
												  @"already consumed",@"failure",
												  nil]];
		} else {
			NSLog(@"{billing} Consuming: %@", token);

			[self.purchases removeObjectForKey:token];

			[[SKPaymentQueue defaultQueue] finishTransaction:transaction];

			// TODO: If something fails at this point the player will lose their purchase.

			[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
												  @"billingConsume",@"name",
												  token,@"token",
												  [NSNull null],@"failure",
												  nil]];
		}
	}
	@catch (NSException *exception) {
		NSLog(@"{billing} WARNING: Unable to consume item: %@", exception);

		[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
											  @"billingConsume",@"name",
											  token ? token : [NSNull null],@"token",
											  @"failed",@"failure",
											  nil]];
	}
}

- (void) getPurchases:(NSDictionary *)jsonObject {
	// Send the list of purchases that may have been missed by the JavaScript during startup
	@try {
		NSMutableArray *skus = [NSMutableArray array];
		NSMutableArray *tokens = [NSMutableArray array];

		for (SKPaymentTransaction *transaction in self.purchases) {
			NSString *sku = transaction.payment.productIdentifier;
			NSString *token = transaction.transactionIdentifier;

			[skus addObject:sku];
			[tokens addObject:token];
		}

		NSLog(@"{billing} Notifying wrapper of %d existing purchases", (int)[skus count]);

		[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
											  @"billingOwned",@"name",
											  skus,@"skus",
											  tokens,@"tokens",
											  [NSNull null],@"failure",
											  nil]];
	}
	@catch (NSException *exception) {
		NSLog(@"{billing} WARNING: Unable to get purchases: %@", exception);
		[[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
											  @"billingOwned",@"name",
											  [NSNull null],@"skus",
											  [NSNull null],@"tokens",
											  @"failed",@"failure",
											  nil]];
	}
}

@end
