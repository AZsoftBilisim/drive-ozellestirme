
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)
	|	AND ValueAllowed(T1.Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|	ON AccountingDimensionByPartners.DimensionKey = ThisList.AccountingDimensionByPartners
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = AccountingDimensionByPartners.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)";


EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	GroupOfTypeOfNotificationsARAPAccounting = UserNotificationsOfEvents.NotificationTypeGroup("SettlementsWithClients");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "f934a8a3-1895-4f45-bc1b-5116666bd34e";
	NewTypeOfAlerts.Description = NStr("vi = 'Đã quá hạn thanh toán trước khi đảm bảo';
										|ru = 'Просрочена оплата до обеспечения';
										|en = 'Overdue payment before supply'; fa = 'Overdue payment before supply';
										|it = 'Overdue payment before supply';
										|pl = 'Overdue payment before supply';
										|tr = 'Tedarik öncesi ödeme gecikti'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Templates.Notifications_AdvancePaymentIsOverdue.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã quá hạn thanh toán trước khi đảm bảo [Sum] [Currency].';
												|ru = 'Просрочена оплата до обеспечения [Sum] [Currency].';
												|en = 'The payment before supply of [Sum] [Currency] is overdue.';
												|it = 'The payment before supply of [Sum] [Currency] is overdue.';
												|pl = 'The payment before supply of [Sum] [Currency] is overdue.';
												|tr = 'Tedarik öncesi ödeme gecikti [Sum] [Currency].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã quá hạn thanh toán trước khi đảm bảo.';
												|ru = 'Просрочена оплата до обеспечения.';
												|en = 'The payment before supply is overdue.';
												|it = 'The payment before supply is overdue.';
												|pl = 'The payment before supply is overdue.';
												|tr = 'Tedarik öncesi ödeme gecikti.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "a522e527-b592-4661-afa0-68f211d6cc3d";
	NewTypeOfAlerts.Description = NStr("vi = 'Sắp đến hạn thanh toán trước khi đảm bảo';
										|ru = 'Приближение срока оплаты до обеспечения';
										|en = 'Approaching payment due date before supply'; fa = 'Approaching payment due date before supply';
										|it = 'Approaching payment due date before supply';
										|pl = 'Approaching payment due date before supply';
										|tr = 'Tedarik öncesi ödeme süresinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Templates.Notifications_AdvancePaymenttIsComing.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Sắp đến hạn thanh toán trước khi đảm bảo với số tiền [Sum] [Currency].';
												|ru = 'Приближается срок оплаты до обеспечения на сумму [Sum] [Currency].';
												|en = 'The payment due date before supply in the amount of [Sum] [Currency] is coming.';
												|it = 'The payment due date before supply in the amount of [Sum] [Currency] is coming.';
												|pl = 'The payment due date before supply in the amount of [Sum] [Currency] is coming.';
												|tr = '[Sum] [Currency] tutarındaki tedarik öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Sắp đến hạn thanh toán trước khi đảm bảo.';
												|ru = 'Приближается срок оплаты до обеспечения.';
												|en = 'The payment due date before supply is coming.';
												|it = 'The payment due date before supply is coming.';
												|pl = 'The payment due date before supply is coming.';
												|tr = 'Tedarik öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "821055bb-7330-4e85-9c28-e4631d36b161";
	NewTypeOfAlerts.Description = NStr("vi = 'Đã quá hạn thanh toán trước khi giao hàng';
										|ru = 'Просрочена оплата до отгрузки';
										|en = 'Overdue payment before shipment'; fa = 'Overdue payment before shipment';
										|it = 'Overdue payment before shipment';
										|pl = 'Overdue payment before shipment';
										|tr = 'Sevkiyat öncesi ödeme gecikti'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Templates.Notifications_PrepaymentIsOverdue.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã quá hạn thanh toán trước khi giao hàng [Sum] [Currency].';
												|ru = 'Просрочена оплата до отгрузки [Sum] [Currency].';
												|en = 'The payment before shipment of [Sum] [Currency] is overdue.';
												|it = 'The payment before shipment of [Sum] [Currency] is overdue.';
												|pl = 'The payment before shipment of [Sum] [Currency] is overdue.';
												|tr = 'Sevkiyat öncesi ödeme gecikti [Sum] [Currency].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã quá hạn thanh toán trước khi giao hàng.';
												|ru = 'Просрочена оплата до отгрузки.';
												|en = 'The payment before shipment is overdue.';
												|it = 'The payment before shipment is overdue.';
												|pl = 'The payment before shipment is overdue.';
												|tr = 'Sevkiyat öncesi ödeme gecikti.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "2e08af04-0dc4-4190-bd77-b3771d675b90";
	NewTypeOfAlerts.Description = NStr("vi = 'Sắp đến hạn thanh toán trước khi giao hàng';
										|ru = 'Приближение срока оплаты до отгрузки';
										|en = 'Approaching payment due date before shipment'; fa = 'Approaching payment due date before shipment';
										|it = 'Approaching payment due date before shipment';
										|pl = 'Approaching payment due date before shipment';
										|tr = 'Sevkiyat öncesi ödeme süresinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Templates.Notifications_PrepaymentIsComing.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Sắp đến hạn thanh toán trước khi giao hàng với số tiền [Sum] [Currency].';
												|ru = 'Приближается срок оплаты до отгрузки на сумму [Sum] [Currency].';
												|en = 'The payment due date before shipment in the amount of [Sum] [Currency] is coming.';
												|it = 'The payment due date before shipment in the amount of [Sum] [Currency] is coming.';
												|pl = 'The payment due date before shipment in the amount of [Sum] [Currency] is coming.';
												|tr = '[Sum] [Currency] tutarındaki sevkiyat öncesi ödeme yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Sắp đến hạn thanh toán trước khi giao hàng.';
												|ru = 'Приближается срок оплаты до отгрузки.';
												|en = 'The payment due date before shipment is coming.';
												|it = 'The payment due date before shipment is coming.';
												|pl = 'The payment due date before shipment is coming.';
												|tr = 'Sevkiyat öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	
	NewTypeOfAlerts.Id = "ef70779c-92c3-46e9-8622-f401fc4f0bb2";
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Description = NStr("vi = 'Khách hàng đã quá hạn thanh toán';
										|ru = 'Просрочена оплата от клиента';
										|en = 'Overdue payment from customer'; fa = 'Overdue payment from customer';
										|it = 'Overdue payment from customer';
										|pl = 'Overdue payment from customer';
										|tr = 'Müşteri tarafından ödeme gecikti'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Templates.Notifications_CreditIsOverdue.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã quá hạn thanh toán [Sum] [Currency].';
												|ru = 'Просрочена оплата [Sum] [Currency].';
												|en = 'The payment of [Sum] [Currency] is overdue.';
												|it = 'The payment of [Sum] [Currency] is overdue.';
												|pl = 'The payment of [Sum] [Currency] is overdue.';
												|tr = '[Sum] [Currency] ödeme gecikti.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã quá hạn thanh toán.';
												|ru = 'Просрочена оплата.';
												|en = 'The payment is overdue.';
												|it = 'The payment is overdue.';
												|pl = 'The payment is overdue.';
												|tr = 'Ödeme gecikti.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "08d7d3c3-85c7-4102-b416-d2c5ff55761f";
	NewTypeOfAlerts.Description = NStr("vi = 'Khách hàng sắp đến hạn thanh toán';
										|ru = 'Приближение срока оплаты от клиента';
										|en = 'Approaching payment from customer'; fa = 'Approaching payment from customer';
										|it = 'Approaching payment from customer';
										|pl = 'Approaching payment from customer';
										|tr = 'Müşteri tarafından yapılacak ödeme süresinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.Templates.Notifications_CreditIsComing.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Sắp đến hạn thanh toán với số tiền [Sum] [Currency].';
												|ru = 'Приближается срок оплаты на сумму [Sum] [Currency].';
												|en = 'The payment due date in the amount of [Sum] [Currency] is coming.';
												|it = 'The payment due date in the amount of [Sum] [Currency] is coming.';
												|pl = 'The payment due date in the amount of [Sum] [Currency] is coming.';
												|tr = '[Sum] [Currency] tutarındaki ödeme süresi yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Sắp đến hạn thanh toán.';
												|ru = 'Приближается срок оплаты.';
												|en = 'The payment due date is coming.';
												|it = 'The payment due date is coming.';
												|pl = 'The payment due date is coming.';
												|tr = 'Ödeme süresi yaklaşıyor.'"; // @NStr-1
EndProcedure

#EndRegion

#EndRegion

#EndIf