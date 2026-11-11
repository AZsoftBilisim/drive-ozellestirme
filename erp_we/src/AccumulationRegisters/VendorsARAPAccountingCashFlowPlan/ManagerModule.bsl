
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

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	GroupOfTypeOfNotificationsARAPAccounting = UserNotificationsOfEvents.NotificationTypeGroup("SettlementsWithSuppliers");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "fd23450d-ba3c-40c5-a543-a567e536d497";
	NewTypeOfAlerts.Description = NStr("vi = 'Đã quá hạn thanh toán trước khi xác nhận';
										|ru = 'Просрочена оплата до подтверждения';
										|en = 'Overdue payment before confirmation'; fa = 'Overdue payment before confirmation';
										|it = 'Overdue payment before confirmation';
										|pl = 'Overdue payment before confirmation';
										|tr = 'Doğrulama öncesi ödeme gecikti'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Templates.Notifications_AdvancePaymentIsOverdue.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã quá hạn thanh toán trước khi xác nhận [Sum] [Currency].';
												|ru = 'Просрочена оплата до подтверждения [Sum] [Currency].';
												|en = 'The payment before confirmation of [Sum] [Currency] is overdue.';
												|it = 'The payment before confirmation of [Sum] [Currency] is overdue.';
												|pl = 'The payment before confirmation of [Sum] [Currency] is overdue.';
												|tr = 'Doğrulama öncesi ödeme gecikti [Sum] [Currency].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã quá hạn thanh toán trước khi xác nhận.';
												|ru = 'Просрочена оплата до подтверждения.';
												|en = 'The payment before confirmation is overdue.';
												|it = 'The payment before confirmation is overdue.';
												|pl = 'The payment before confirmation is overdue.';
												|tr = 'Doğrulama öncesi ödeme gecikti.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "89a85149-1099-4f5d-bcc7-694c518533bb";
	NewTypeOfAlerts.Description = NStr("vi = 'Sắp đến hạn thanh toán trước khi xác nhận';
										|ru = 'Приближение срока оплаты до подтверждения';
										|en = 'Approaching payment due date before confirmation'; fa = 'Approaching payment due date before confirmation';
										|it = 'Approaching payment due date before confirmation';
										|pl = 'Approaching payment due date before confirmation';
										|tr = 'Doğrulama öncesi ödeme süresinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Templates.Notifications_AdvancePaymenttIsComing.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Sắp đến hạn thanh toán trước khi xác nhận với số tiền [Sum] [Currency].';
												|ru = 'Приближается срок оплаты до подтверждения на сумму [Sum] [Currency].';
												|en = 'The payment due date before confirmation in the amount of [Sum] [Currency] is coming.';
												|it = 'The payment due date before confirmation in the amount of [Sum] [Currency] is coming.';
												|pl = 'The payment due date before confirmation in the amount of [Sum] [Currency] is coming.';
												|tr = '[Sum] [Currency] tutarında doğrulama öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Sắp đến hạn thanh toán trước khi xác nhận.';
												|ru = 'Приближается срок оплаты до подтверждения.';
												|en = 'The payment due date before confirmation is coming.';
												|it = 'The payment due date before confirmation is coming.';
												|pl = 'The payment due date before confirmation is coming.';
												|tr = 'Doğrulama öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "6f0797a9-cfc4-4917-b3cc-13849ea928b8";
	NewTypeOfAlerts.Description = NStr("vi = 'Đã quá hạn thanh toán trước khi tiếp nhận';
										|ru = 'Просрочена оплата до поступления';
										|en = 'Overdue payment before receipt'; fa = 'Overdue payment before receipt';
										|it = 'Overdue payment before receipt';
										|pl = 'Overdue payment before receipt';
										|tr = 'Teslim öncesi ödeme gecikti'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Templates.Notifications_PrepaymentIsOverdue.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã quá hạn thanh toán trước khi tiếp nhận [Sum] [Currency].';
												|ru = 'Просрочена оплата до поступления [Sum] [Currency].';
												|en = 'The payment before receipt of [Sum] [Currency] is overdue.';
												|it = 'The payment before receipt of [Sum] [Currency] is overdue.';
												|pl = 'The payment before receipt of [Sum] [Currency] is overdue.';
												|tr = 'Teslim öncesi ödeme gecikti [Sum] [Currency].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã quá hạn thanh toán trước khi tiếp nhận.';
												|ru = 'Просрочена оплата до поступления.';
												|en = 'The payment before receipt is overdue.';
												|it = 'The payment before receipt is overdue.';
												|pl = 'The payment before receipt is overdue.';
												|tr = 'Teslim öncesi ödeme gecikti.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "ba505486-f040-4f25-8d59-179876323905";
	NewTypeOfAlerts.Description = NStr("vi = 'Sắp đến hạn thanh toán trước khi tiếp nhận';
										|ru = 'Приближение срока оплаты до поступления';
										|en = 'Approaching payment due date before receipt'; fa = 'Approaching payment due date before receipt';
										|it = 'Approaching payment due date before receipt';
										|pl = 'Approaching payment due date before receipt';
										|tr = 'Teslim öncesi ödeme süresinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Templates.Notifications_PrepaymentIsComing.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Sắp đến hạn thanh toán trước khi tiếp nhận với số tiền [Sum] [Currency].';
												|ru = 'Приближается срок оплаты до поступления на сумму [Sum] [Currency].';
												|en = 'The payment due date before receipt in the amount of [Sum] [Currency] is coming.';
												|it = 'The payment due date before receipt in the amount of [Sum] [Currency] is coming.';
												|pl = 'The payment due date before receipt in the amount of [Sum] [Currency] is coming.';
												|tr = '[Sum] [Currency] tutarında teslim öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Sắp đến hạn thanh toán trước khi tiếp nhận.';
												|ru = 'Приближается срок оплаты до поступления.';
												|en = 'The payment due date before receipt is coming.';
												|it = 'The payment due date before receipt is coming.';
												|pl = 'The payment due date before receipt is coming.';
												|tr = 'Teslim öncesi ödeme süresi yaklaşıyor.'"; // @NStr-1
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	
	NewTypeOfAlerts.Id = "69c089ef-8853-4fe7-a15c-d30a2b8f2fb7";
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Description = NStr("vi = 'Đã quá hạn thanh toán cho nhà cung cấp';
										|ru = 'Просрочена оплата поставщику';
										|en = 'Overdue payment to vendor'; fa = 'Overdue payment to vendor';
										|it = 'Overdue payment to vendor';
										|pl = 'Overdue payment to vendor';
										|tr = 'Tedarikçiye ödeme gecikti'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Templates.Notifications_CreditIsOverdue.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã quá hạn thanh toán [Sum] [Currency].';
												|ru = 'Просрочена оплата [Sum] [Currency].';
												|en = 'The payment of [Sum] [Currency] is overdue.';
												|it = 'The payment of [Sum] [Currency] is overdue.';
												|pl = 'The payment of [Sum] [Currency] is overdue.';
												|tr = '[Sum] [Currency] ödeme gecikti.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã quá hạn thanh toán sau khi tiếp nhận.';
												|ru = 'Просрочена оплата после поступления.';
												|en = 'The payment after receipt is overdue.';
												|it = 'The payment after receipt is overdue.';
												|pl = 'The payment after receipt is overdue.';
												|tr = 'Teslim sonrası ödeme gecikti.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "0ca6e8bf-6067-450c-b881-d8a21b95e363";
	NewTypeOfAlerts.Description = NStr("vi = 'Sắp đến hạn thanh toán cho nhà cung cấp';
										|ru = 'Приближение срока оплаты поставщику';
										|en = 'Approaching due date of payment to vendor'; fa = 'Approaching due date of payment to vendor';
										|it = 'Approaching due date of payment to vendor';
										|pl = 'Approaching due date of payment to vendor';
										|tr = 'Tedarikçiye ödeme süresinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.Templates.Notifications_CreditIsComing.FullName();
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