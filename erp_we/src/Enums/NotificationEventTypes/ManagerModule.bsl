#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns whether the scheduled task needs to be configured.
//
// Parameters:
//  EventType  - EnumRef.NotificationEventTypes - the type of alert event for which the attribute is obtained.
//
// Returns:
//   Boolean   - True if the setting is required.
//
Function SettingUpRoutineTaskIsRequired(EventType) Export
	
	If EventType = Enums.NotificationEventTypes.ARAPOverdue
		Or EventType = Enums.NotificationEventTypes.HappyBirthdayWishes
		Or EventType = Enums.NotificationEventTypes.ScheduledPayments
		Or EventType = Enums.NotificationEventTypes.PlannedShipments 
		Or EventType = Enums.NotificationEventTypes.SurveyEnd Then
	
		Return True;
	
	Else
	
		Return ConfigurationModificationOverridable.EventTypeRequiresSettingUpRoutineTask(EventType);
	
	EndIf
	
EndFunction

// Returns settings for the event types that are required when processing the mailing queue and notifications.
//
// Parameters:
//  EventType  - EnumRef.NotificationEventTypes - the type of alert event to get settings for.
//
// Returns:
//   Structure   - contains settings:
//     *  PathToContactPerson - String -the path to the contact person of the notification object from the notification source.
//     *  SendToCustomer - Boolean - indicates that notifications by type can be sent to partners.
//     *  SendNotificationsToObjectSContactPersons - Boolean - indicates that notifications by type can be contact
//                                                             the person of the notification object.
//     *  SendToPartnerSContactPersons - Boolean - indicates that notifications by type can be sent
//                                                    to the partner's contact persons.
//     *  Name - String - the name of the enumeration.
//
Function DataForProcessingAlertQueue(EventType) Export
	
	StructureOfData = DataStructureForAlerts();
	
	If EventType = Enums.NotificationEventTypes.HappyBirthdayWishes Then
		
		StructureOfData.PathToContactPerson                             = "";
		StructureOfData.SendToCustomer                               = False;
		StructureOfData.SendToPartnerSContactPersons                = False;
		StructureOfData.Name                                              = "HappyBirthdayWishes";
		
	ElsIf EventType = Enums.NotificationEventTypes.ARAPOverdue Then
		
		StructureOfData.SendNotificationsToObjectSContactPersons       = False;
		StructureOfData.Name                                              = "ARAPOverdue";
		
	ElsIf EventType = Enums.NotificationEventTypes.ScheduledPayments Then
		
		StructureOfData.SendNotificationsToObjectSContactPersons       = False;
		StructureOfData.Name                                              = "ScheduledPayments";
		
	ElsIf EventType = Enums.NotificationEventTypes.BonusAccrual Then
		
		StructureOfData.SendNotificationsToObjectSContactPersons       = False;
		StructureOfData.Name                                              = "BonusAccrual";
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseLoyaltyPrograms")
		                                                                    And AccessRight("Read", Metadata.Documents.AccrueAndDeductionOfBonusPoints)
		                                                                    And AccessRight("Read", Metadata.AccumulationRegisters.BonusPoints);
		
	ElsIf EventType = Enums.NotificationEventTypes.DeductionOfBonuses Then
		
		StructureOfData.SendNotificationsToObjectSContactPersons       = False;
		StructureOfData.Name                                              = "DeductionOfBonuses";
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseLoyaltyPrograms")
		                                                                    And AccessRight("Read", Metadata.Documents.AccrueAndDeductionOfBonusPoints)
		                                                                    And AccessRight("Read", Metadata.AccumulationRegisters.BonusPoints);
		
	ElsIf EventType = Enums.NotificationEventTypes.OrderStatusChange Then
		
		StructureOfData.PathToContactPerson                             = ".ContactPerson";
		StructureOfData.Name                                              = "OrderStatusChange";
		StructureOfData.ExternalLinkIsAvailableInTemplate                    = True;
		StructureOfData.MetadataOfAlertSource                    = Metadata.Documents.SalesOrder;
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseSalesOrders")
																			And AccessRight("Read", Metadata.Documents.SalesOrder);
		
	ElsIf EventType = Enums.NotificationEventTypes.PlannedShipments Then
		
		StructureOfData.PathToContactPerson                             = ".ContactPerson";
		StructureOfData.Name                                              = "PlannedShipments";
		StructureOfData.AvailableForUse                         = AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
		
	ElsIf EventType = Enums.NotificationEventTypes.AccountStatement Then
		
		StructureOfData.PathToContactPerson                             = ".ContactPerson";
		StructureOfData.Name                                              = "AccountStatement";
		StructureOfData.ExternalLinkIsAvailableInTemplate                    = True;
		StructureOfData.MetadataOfAlertSource                    = Metadata.Documents.CustomerCommercialInvoice;
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseCustomerCommercialInvoices")
																			And AccessRight("Read", Metadata.Documents.CustomerCommercialInvoice);
		
	ElsIf EventType = Enums.NotificationEventTypes.CommercialInvoiceCancellation Then
		
		StructureOfData.PathToContactPerson                             = ".ContactPerson";
		StructureOfData.Name                                              = "CommercialInvoiceCancellation";
		StructureOfData.ExternalLinkIsAvailableInTemplate                    = True;
		StructureOfData.MetadataOfAlertSource                    = Metadata.Documents.CustomerCommercialInvoice;
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseCustomerCommercialInvoices")
																			And AccessRight("Read", Metadata.Documents.CustomerCommercialInvoice);
		
	ElsIf EventType = Enums.NotificationEventTypes.ChangeOfAccount Then
		
		StructureOfData.PathToContactPerson                             = ".ContactPerson";
		StructureOfData.Name                                              = "ChangeOfAccount";
		StructureOfData.ExternalLinkIsAvailableInTemplate                    = True;
		StructureOfData.MetadataOfAlertSource                    = Metadata.Documents.CustomerCommercialInvoice;
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseCustomerCommercialInvoices")
																			And AccessRight("Read", Metadata.Documents.CustomerCommercialInvoice);
		
	ElsIf EventType = Enums.NotificationEventTypes.CashReceiptFromCustomer Then
		
		StructureOfData.SendNotificationsToObjectSContactPersons       = False;
		StructureOfData.Name                                              = "CashReceiptFromCustomer";
		StructureOfData.AvailableForUse                         = AccessRight("Read", Metadata.Documents.CashAccountReceiptNote)
																			And AccessRight("Read", Metadata.Documents.BankAccountReceiptNote)
																			And AccessRight("Read", Metadata.Documents.PaymentCardTransaction)
																			And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting);
		
	ElsIf EventType = Enums.NotificationEventTypes.SurveyEnd Then
		
		StructureOfData.SendNotificationsToObjectSContactPersons       = False;
		StructureOfData.Name                                              = "SurveyEnd";
		StructureOfData.AvailableForUse                         = GetFunctionalOption("UseSurvey");

		
	Else
		
		ConfigurationModificationOverridable.EventTypeSettingsForHandlingAlertQueue(EventType, StructureOfData);
		
	EndIf;
	
	Return StructureOfData;
	
EndFunction

#EndRegion

#Region Private

Function DataStructureForAlerts()

	StructureOfData = New Structure;

	StructureOfData.Insert("PathToContactPerson", Undefined);
	StructureOfData.Insert("SendNotificationsToObjectSContactPersons", True);
	StructureOfData.Insert("SendToCustomer", True);
	StructureOfData.Insert("SendToPartnerSContactPersons", True);
	StructureOfData.Insert("ExternalLinkIsAvailableInTemplate", False);
	StructureOfData.Insert("MetadataOfAlertSource", Undefined);
	StructureOfData.Insert("AvailableForUse", True);
	StructureOfData.Insert("Name", False);
	
	Return StructureOfData;
	
EndFunction 

#EndRegion

#EndIf
