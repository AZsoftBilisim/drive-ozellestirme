#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
//  See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.CashToBePaid.Name;
	NameOfChangeTable = "CashFlowsPayableChange"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("TreasuryAndARAPAccounting");
	NewTypeOfAlerts.Id = "f898aa4b-c8ce-4b2e-82ac-66bd5e9d7fdd";
	NewTypeOfAlerts.Description = NStr("vi = 'Thanh toán theo giấy đề nghị thanh toán';
										|ru = 'Оплата по заявке на расходование денежных средств';
										|en = 'Payment based on the payment request'; fa = 'Payment based on the payment request';
										|it = 'Payment based on the payment request';
										|pl = 'Payment based on the payment request';
										|tr = 'Nakit harcama talebi kapsamında ödeme'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CashToBePaid.Templates.Notifications_RequestExecution.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã thực hiện thanh toán [Recipient] với số tiền [PaymentAmount] [Currency]. [DocumentPayments]';
												|ru = 'Произведена оплата [Recipient] на сумму [PaymentAmount] [Currency]. [DocumentPayments]';
												|en = 'Payment is made to [Recipient] in the amount of [PaymentAmount] [Currency]. [DocumentPayments]';
												|it = 'Payment is made to [Recipient] in the amount of [PaymentAmount] [Currency]. [DocumentPayments]';
												|pl = 'Payment is made to [Recipient] in the amount of [PaymentAmount] [Currency]. [DocumentPayments]';
												|tr = '[PaymentAmount] [Currency] tutarında [Recipient] ödemesi yapıldı. [DocumentPayments]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts, 
		Metadata.AccumulationRegisters.CashToBePaid.FullName());
	
EndProcedure

#EndRegion

#EndRegion

#EndIf