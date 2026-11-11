#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("CommissionFeeCalculationMethod");
	ArrayOfAllProps.Add("RemunerationPercentage");
	ArrayOfAllProps.Add("KeepCommissionFee");
	ArrayOfAllProps.Add("PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("MaximumPercentageForManualMarkup");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		ArrayOfOperationDetails.Add("CommissionFeeCalculationMethod");
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("KeepCommissionFee");
	ElsIf BusinessOperation = Enums.BusinessTransactions.AgentServicesDelivery Then
		ArrayOfOperationDetails.Add("CommissionFeeCalculationMethod");
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("KeepCommissionFee");
		ArrayOfOperationDetails.Add("ServicesTypes");
		ArrayOfOperationDetails.Add("AgentServices");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseByImport 
			Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU Then
		ArrayOfOperationDetails.Add("PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("MaximumPercentageForManualMarkup");
	Else
		ArrayOfOperationDetails.Add("PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("MaximumPercentageForManualMarkup");
	EndIf;
	
EndProcedure

// Sets the status of agreements with suppliers
//
// Parameters:
//	Terms1 - Array - array of links to supplier agreements
//	Status     - EnumRef.StatusesOfTermsOfPurchase - the status that will be set for agreements.
//
// Returns:
//	Number - the number of processed rows.
//
Function SetStatus(Val Terms1, Val Status) Export
	
	ReferencesArrray = New Array();
	ProcessedItemsCount = 0;
	
	For Each Terms In Terms1 Do
	
		If TypeOf(Terms) = Type("DynamicListGroupRow") Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Terms);
		
	EndDo;
	
	If ReferencesArrray = 0 Then
		Return ProcessedItemsCount;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	TermsOfPurchases.Ref AS Ref,
	|	TermsOfPurchases.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN TermsOfPurchases.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|WHERE
	|	TermsOfPurchases.Ref IN(&ReferencesArrray)");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("Status", Status);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			
			ErrorText = NStr("vi = 'Thỏa thuận %Terms% đã đặt dấu xóa. Không thể thay đổi trạng thái';
							|ru = 'Соглашение %Terms% помечено на удаление. Невозможно изменить статус';
							|en = 'Agreement %Terms% is marked for deletion. Cannot change the status.'; fa = 'Agreement %Terms% is marked for deletion. Cannot change the status.';
							|it = 'L''accordo %Terms% è contrassegnato per la cancellazione. Impossibile modificare lo stato';
							|pl = 'Porozumienie %Terms% jest zaznaczone do usunięcia. Zmiana statusu nie jest możliwa';
							|tr = 'Anlaşma %Terms% silinmek üzere işaretlendi. Durum değiştirilemiyor'");
			ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Ref);
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			Continue;
			
		EndIf;
		
		If Selection.StatusMatches Then
			
			ErrorText = NStr("vi = 'Thỏa thuận %Terms% đã gán trạng thái ""%Status%""';
							|ru = 'Соглашению %Terms% уже присвоен статус ""%Status%""';
							|en = 'Agreement %Terms% is already in status ""%Status%""'; fa = 'Agreement %Terms% is already in status ""%Status%""';
							|it = 'All''accordo %Terms% è già stato assegnato lo stato ""%Status%""';
							|pl = 'Porozumieniu %Terms% przydzielono już status ""%Status%""';
							|tr = '%Terms% anlaşmasına halihazırda ""%Status%"" durumu verilmiştir.'");
			ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%Status%", Status);
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			Continue;
			
		EndIf;
		
		Try
			LockDataForEdit(Selection.Ref);
		Except
			
			ErrorText = NStr("vi = 'Không thể phong tỏa %Terms%. %ErrorDescription%';
							|ru = 'Не удалось заблокировать %Terms%. %ErrorDescription%';
							|en = 'Failed to lock %Terms%. %ErrorDescription%'; fa = 'Failed to lock %Terms%. %ErrorDescription%';
							|it = 'Non è stato possibile bloccare %Terms%. %ErrorDescription%';
							|pl = 'Nie udało się zablokować %Terms%. %ErrorDescription%';
							|tr = '%Terms% bloke edilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			
		EndTry;
		
		Object = Selection.Ref.GetObject();
		Object.Status = Status;
		
		If Status = Enums.StatusesOfTermsOfSales.NotApproved Then
			If Object.Approved Then
				Object.Approved = False;
			EndIf;
		EndIf;
			
		If Not Object.CheckFilling() Then
			Continue;
		EndIf;
			
		Try
			
			Object.Write();
			ProcessedItemsCount = ProcessedItemsCount + 1;
			
		Except
			
			ErrorText = NStr("vi = 'Không thể ghi lại %Terms%. %ErrorDescription%';
							|ru = 'Не удалось записать %Terms%. %ErrorDescription%';
							|en = 'Failed to save %Terms%. %ErrorDescription%'; fa = 'Failed to save %Terms%. %ErrorDescription%';
							|it = 'Non è stato possibile scrivere %Terms%. %ErrorDescription%';
							|pl = 'Nie udało się zapisać %Terms%. %ErrorDescription%';
							|tr = '%Terms% Kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			
		EndTry
		
	EndDo;
	
	Return ProcessedItemsCount;

EndFunction

// Returns a flag for use as an aggregating entity in items to be received.
//
// Parameters:
//  GoodsReceiptOption - EnumRef.GoodsReceiptOptions - link to the acceptance option.
//
// Returns:
//  Boolean - whether or not the acceptance agreement is used.
//
Function AgreementIsUsedForAcceptance(Val GoodsReceiptOption) Export
	
	If Not ValueIsFilled(GoodsReceiptOption) Then
		GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	EndIf;
	
	Result = False;
	If GoodsReceiptOption = Enums.GoodsReceiptOptions.NotDividedByOrdersAndInvoices
		Or GoodsReceiptOption = Enums.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed 
		Or GoodsReceiptOption = Enums.GoodsReceiptOptions.NotSeparatedByInvoices Then 

		Result = True;

	EndIf;

	Return Result;

EndFunction

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

// Creates a default agreement.
//
// Parameters:
//  Parameters - Structure - fill structure.
//
// Returns:
//  CatalogRef.TermsOfPurchaseFromVendors - link to the created agreement.
//
Function CreateDefaultAgreement(Val Parameters) Export
	
	Terms = Catalogs.TermsOfPurchaseFromVendors.CreateItem();
	Terms.Fill(Undefined);
	FillPropertyValues(Terms, Parameters);
	Terms.Date = CurrentSessionDate();
	Terms.Status = Enums.StatusesOfTermsOfPurchase.Valid;
	
	If Not ValueIsFilled(Terms.Description) Then
		Terms.Description = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Điều kiện mua hàng từ %1';
				|ru = 'Условия закупок с %1';
				|en = 'Purchase conditions from %1'; fa = 'Purchase conditions from %1';
				|it = 'Termini di acquisto da %1';
				|pl = 'Warunki zakupów z %1';
				|tr = '%1ile satın alma hüküm ve koşulları'"), Terms.Partner);
	EndIf;
	
	If Not ValueIsFilled(Terms.GoodsReceiptOption) Or GetFunctionalOption("UseReceiptForMultipleOrders") Then
		Terms.GoodsReceiptOption = Enums.GoodsReceiptOptions.NotDividedByOrdersAndInvoices;
	EndIf;
	
	If Not ValueIsFilled(Terms.ForeignCurrencyTransaction) Then
		Terms.ForeignCurrencyTransaction = False;
	EndIf;
	
	Terms.Write();
	
	Return Terms.Ref
	
EndFunction 

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
		
	QueryText =
	"SELECT
	|	Header.Number									AS Number,
	|	TRUE										AS Posted,
	|	Header.Ref								AS Ref,
	|	Header.Date									AS Date,
	|	Header.Partner								AS RecipientSender,
	|	Header.CarrierPartner						AS Carrier,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|			THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE Header.DeliveryMethod
	|	END										AS DeliveryMethod,
	|	Header.DeliveryZone							AS Zone,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|	END										AS Address,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|	END										AS FieldValueAddress,
	|	Header.DeliveryTimeFrom						AS TimeFrom,
	|	Header.DeliveryTimeTo						AS TimeTo,
	|	Header.AdditionalDeliveryInformation	AS AdditionalInformation,
	|	Header.Warehouse									AS Warehouse,
	|	FALSE										AS DeliverFully,
	|	FALSE 										AS SpecialTransportationConditions,
	|	""""										AS SpecialTransportationConditionsDescription,
	|	FALSE										AS SplitGoodsIssueNotesByReferences	
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS Header
	|WHERE
	|	Header.Ref IN(&References)";
	
	Return QueryText;
	
EndFunction

// The function returns the text of the request to receive goods for delivery by order
//
// Returns:
//  String - Query text
//
Function QueryTextGoodsToDeliver() Export
	
	QueryText =
	"SELECT
	|	GoodsToReceiveBalance.DocumentInflow AS Ref,
	|	GoodsToReceiveBalance.Products AS Products,
	|	GoodsToReceiveBalance.Characteristic AS Characteristic,
	|	GoodsToReceiveBalance.Purpose AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	GoodsToReceiveBalance.Warehouse AS Warehouse,
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow IN (&References)) AS GoodsToReceiveBalance";
	
	Return QueryText;
	
EndFunction

// Adds a command to create the supplier Agreement directory.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	
	ObjectMetadata =  Metadata.Catalogs.TermsOfPurchaseFromVendors;
	
	If AccessRight("Insert",ObjectMetadata) And GetFunctionalOption("UseTermsOfPurchases") Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = ObjectMetadata.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(ObjectMetadata);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ContractsAreUsed,ARAPObjectSettings", Parameters);
	
EndProcedure

// Returns the business of operation of the agreement with the supplier.
//
// Parameters:
//   Terms - CatalogRef.TermsOfPurchaseFromVendors
//
// Returns:
//   EnumRef.BusinessTransactions
Function BusinessTransactionFromAgreement(Terms) Export
	
	If Not ValueIsFilled(Terms) Then
		Return Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TermsOfPurchaseFromVendors.BusinessOperation AS BusinessOperation
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|WHERE
	|	TermsOfPurchaseFromVendors.Ref = &Terms";
	Query.SetParameter("Terms", Terms);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.BusinessOperation;
	Else
		Return Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
// ObjectOrRef - CatalogObject.TermsOfPurchaseFromVendors, CatalogRef.TermsOfPurchaseFromVendors - Agreement.
// FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Partner,
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Ref;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.DateOfReceipt = '00010101';
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = '00010101';
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = Catalogs.BusinessStructure.EmptyRef();
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Attributes.Sender = ObjectAttributes.Partner;
	
	Return Attributes;
	
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
	|	ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse, EmptyRef AS TRUE)
	|	AND ValueAllowed(Organization, EmptyRef AS TRUE)";

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	PurchasingNotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Purchases");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "59ae77c7-6aeb-4e72-935a-0ee6e6c28c5d";
	NewTypeOfAlerts.Description = NStr("vi = 'Thống nhất các thỏa thuận về điều kiện bán hàng';
										|ru = 'Согласование соглашений об условиях закупок';
										|en = 'Terms of purchase approval'; fa = 'Terms of purchase approval';
										|it = 'Terms of purchase approval';
										|pl = 'Terms of purchase approval';
										|tr = 'Satın alma şartlarına ilişkin anlaşmaların mutabakatı'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.TermsOfPurchaseFromVendors.Templates.Notifications_Approval.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Thống nhất thỏa thuận.';
												|ru = 'Согласовать соглашение.';
												|en = 'Approve terms.';
												|it = 'Approve terms.';
												|pl = 'Approve terms.';
												|tr = 'Anlaşmayı onayla.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Thống nhất các thỏa thuận về điều kiện bán hàng.';
												|ru = 'Согласовать соглашения об условиях закупок.';
												|en = 'Approve terms of purchase.';
												|it = 'Approve terms of purchase.';
												|pl = 'Approve terms of purchase.';
												|tr = 'Satın alma şartlarına ilişkin anlaşmaları onayla.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "96f98c9e-9183-4842-9518-64ff1af03391";
	NewTypeOfAlerts.Description = NStr("vi = 'Ngày hết hiệu lực của các thỏa thuận về điều kiện mua hàng đang đến gần';
										|ru = 'Приближение даты окончания действия соглашений об условиях закупок';
										|en = 'Approach of terms of purchase expiration date'; fa = 'Approach of terms of purchase expiration date';
										|it = 'Approach of terms of purchase expiration date';
										|pl = 'Approach of terms of purchase expiration date';
										|tr = 'Satın alma şartlarına ilişkin anlaşmaların sona erme tarihinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.TermsOfPurchaseFromVendors.Templates.Notifications_ExpirationDateIsApproaching.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Kết thúc thời hạn hiệu lực của thỏa thuận [ValidityEndDate].';
												|ru = 'Заканчивается срок действия соглашения [ValidityEndDate].';
												|en = 'The terms are expiring on [ValidityEndDate].';
												|it = 'The terms are expiring on [ValidityEndDate].';
												|pl = 'The terms are expiring on [ValidityEndDate].';
												|tr = 'Anlaşmanın geçerlilik süresi sona eriyor [ValidityEndDate].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Kết thúc thời hạn hiệu lực của thỏa thuận về điều kiện mua hàng.';
												|ru = 'Заканчивается срок действия соглашений об условиях закупок.';
												|en = 'Terms of purchase are expiring.';
												|it = 'Terms of purchase are expiring.';
												|pl = 'Terms of purchase are expiring.';
												|tr = 'Satın alma şartlarına ilişkin anlaşmaların geçerlilik süresi sona eriyor.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "399811b6-c50d-4060-a2b0-5ae8c7fc16cd";
	NewTypeOfAlerts.Description = NStr("vi = 'Kết thúc thời hạn hiệu lực của thỏa thuận về điều kiện mua hàng';
										|ru = 'Окончание срока действия соглашений об условиях закупок';
										|en = 'Terms of purchase expiration'; fa = 'Terms of purchase expiration';
										|it = 'Terms of purchase expiration';
										|pl = 'Terms of purchase expiration';
										|tr = 'Satın alma şartlarına ilişkin anlaşmaların geçerlilik süresinin sona ermesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.TermsOfPurchaseFromVendors.Templates.Notifications_ExpirationDateIsOver.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã kết thúc thời hạn hiệu lực của thỏa thuận [ValidityEndDate].';
												|ru = 'Закончился срок действия соглашения [ValidityEndDate].';
												|en = 'The terms expired on [ValidityEndDate].';
												|it = 'The terms expired on [ValidityEndDate].';
												|pl = 'The terms expired on [ValidityEndDate].';
												|tr = 'Anlaşmanın geçerlilik süresi sona erdi [ValidityEndDate].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã kết thúc thời hạn hiệu lực của thỏa thuận về điều kiện mua hàng.';
												|ru = 'Закончился срок действия соглашений об условиях закупок.';
												|en = 'Terms of purchase expired.';
												|it = 'Terms of purchase expired.';
												|pl = 'Terms of purchase expired.';
												|tr = 'Satın alma şartlarına ilişkin anlaşmaların geçerlilik süresi sona erdi.'"; // @NStr-1
EndProcedure

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	Partner       = Catalogs.Partners.EmptyRef();
	BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	DocumentDate = CurrentSessionDate();
	SearchString  = "";
	ContractsAreUsed = Undefined;
	
	If Parameters.Filter.Property("Partner") Then
		Partner = Parameters.Filter.Partner;
	EndIf;
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
		
	If Parameters.Filter.Property("Date") Then
		DocumentDate = Parameters.Filter.Date;
	EndIf;
	
	Parameters.Property("SearchString",SearchString);
	
	QueryText = "	
		|SELECT ALLOWED TOP 51
		|	CatalogTermsOfPurchases.Ref       AS Ref,
		|	CatalogTermsOfPurchases.Description AS Description,
		|	CatalogTermsOfPurchases.Number        AS Number,
		|	CatalogTermsOfPurchases.Date         AS Date,
		|	CASE
		|		WHEN
		|			CatalogTermsOfPurchases.DeletionMark
		|		THEN
		|			0
		|		WHEN
		|			CatalogTermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|		THEN
		|			0
		|		WHEN
		|			CatalogTermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.NotApproved)
		|		THEN
		|			1
		|	END AS PictureIndex,
		|
		|	CASE
		|		WHEN
		|			CatalogTermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|			AND ((CatalogTermsOfPurchases.ValidityStartDate <> DATETIME(1,1,1) AND
		|			CatalogTermsOfPurchases.ValidityStartDate > &DocumentDate))
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS TheValidityPeriodHasNotCome,
		|
		|	CASE
		|		WHEN
		|			CatalogTermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|			AND ((CatalogTermsOfPurchases.ValidityEndDate <> DATETIME(1,1,1) AND
		|			CatalogTermsOfPurchases.ValidityEndDate < &DocumentDate))
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ValidityPeriodExpired
		|
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS CatalogTermsOfPurchases
		|WHERE
		|	CatalogTermsOfPurchases.Partner = &Partner
		|	AND CatalogTermsOfPurchases.Status <> VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
		|	AND (CatalogTermsOfPurchases.Description LIKE &SearchString ESCAPE ""~""
		|	OR CatalogTermsOfPurchases.Number LIKE &SearchString ESCAPE ""~"")
		|";
	
	
	If Parameters.Filter.Property("BusinessOperation", BusinessOperation) Then
		If TypeOf(BusinessOperation) = Type("EnumRef.BusinessTransactions") Then
			QueryText = QueryText + "
				|	AND CatalogTermsOfPurchases.BusinessOperation = &BusinessOperation";
		ElsIf TypeOf(BusinessOperation) = Type("Array") Then 
			QueryText = QueryText + "
				|	AND CatalogTermsOfPurchases.BusinessOperation IN(&BusinessOperation)";
		EndIf;
	EndIf;
	If Parameters.Filter.Property("ContractsAreUsed", ContractsAreUsed) Then
		If ContractsAreUsed <> Undefined Then 
			QueryText = QueryText + "
					|	AND CatalogTermsOfPurchases.ContractsAreUsed = &ContractsAreUsed";
		EndIf;
	EndIf;
	
	PriceIncludesVAT = False;
	If Parameters.Filter.Property("PriceIncludesVAT", PriceIncludesVAT) Then
		QueryText = QueryText + "
			|	AND CatalogTermsOfPurchases.PriceIncludesVAT = &PriceIncludesVAT";
	EndIf; 
	
	QueryText = QueryText + "
		|ORDER BY
		|	ValidityStartDate ASC,
		|	ValidityEndDate ASC
		|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Partner",       			Partner);
	Query.SetParameter("DocumentDate", 			BegOfDay(DocumentDate));
	Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	Query.SetParameter("BusinessOperation", 	BusinessOperation);
	Query.SetParameter("ContractsAreUsed", ContractsAreUsed);
	Query.SetParameter("PriceIncludesVAT", PriceIncludesVAT);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		ChoiceData = New ValueList();
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.Description) And
				ValueIsFilled(Selection.Date) And
				ValueIsFilled(Selection.Number) Then
				
				Presentation = NStr("vi = '%Description% (%Number% ngày %Date%)';
									|ru = '%Description% (%Number% от %Date%)';
									|en = '%Description% (%Number% from %Date%)'; fa = '%Description% (%Number% from %Date%)';
									|it = '%Description% (%Number% dal %Date%)';
									|pl = '%Description% (%Number% z dn. %Date%)';
									|tr = '%Description%(%Date% itibarıyla %Number%)'");
				Presentation = StrReplace(Presentation,"%Description%", Selection.Description);
				Presentation = StrReplace(Presentation,"%Number%",        Selection.Number);
				Presentation = StrReplace(Presentation,"%Date%",         Format(Selection.Date, "DLF=D"));
				
			ElsIf ValueIsFilled(Selection.Description) And
				ValueIsFilled(Selection.Date) Then
				
				Presentation = NStr("vi = '%Description% (ngày %Ngày%)';
									|ru = '%Description% (от %Date%)';
									|en = '%Description% (from %Date%)'; fa = '%Description% (from %Date%)';
									|it = '%Description% (dal %Date%)';
									|pl = '%Description% (z dn. %Date%)';
									|tr = '%Description% (%Date% itibarıyla)'");
				Presentation = StrReplace(Presentation,"%Description%", Selection.Description);
				Presentation = StrReplace(Presentation,"%Date%",         Format(Selection.Date, "DLF=D"));
				
			ElsIf ValueIsFilled(Selection.Description) And
				ValueIsFilled(Selection.Number) Then
				
				Presentation = NStr("vi = '%Description% (%Number%)';
									|ru = '%Description% (%Number%)';
									|en = '%Description% (%Number%)'; fa = '%Description% (%Number%)';
									|it = '%Description%(%Number%)';
									|pl = '%Description% (%Number%)';
									|tr = '%Description% (%Number%)'");
				Presentation = StrReplace(Presentation,"%Description%", Selection.Description);
				Presentation = StrReplace(Presentation,"%Number%",        Selection.Number);
				
			Else
				
				Presentation = NStr("vi = '%Description%';
									|ru = '%Description%';
									|en = '%Description%'; fa = '%Description%';
									|it = '%Description%';
									|pl = '%Description%';
									|tr = '%Description%'");
				Presentation = StrReplace(Presentation,"%Description%", Selection.Description);
				
			EndIf;
			
			Structure = New Structure();
			Structure.Insert("Value", Selection.Ref);
			
			If Selection.TheValidityPeriodHasNotCome Then
				Structure.Insert("Warning", NStr("vi = 'Ở thỏa thuận không có thời hạn hiệu lực';
												|ru = 'У соглашения не наступил срок действия.';
												|en = 'The agreement is not within its validity period.'; fa = 'The agreement is not within its validity period.';
												|it = 'L''accordo non è ancora entrato in vigore.';
												|pl = 'Termin wejścia w życie porozumienia jeszcze nie nastąpił.';
												|tr = 'Anlaşmanın süresi henüz dolmamıştır.'"));
			ElsIf Selection.ValidityPeriodExpired Then
				Structure.Insert("Warning", NStr("vi = 'Ở thỏa thuận quá thời hạn hiệu lực';
												|ru = 'У соглашения истек срок действия.';
												|en = 'The agreement has expired.'; fa = 'The agreement has expired.';
												|it = 'L''accordo è scaduto.';
												|pl = 'Porozumienie wygasło.';
												|tr = 'Anlaşmanın süresi dolmuştur.'"));
			EndIf;
			
			If Selection.PictureIndex = 0 Then
				Picture = PictureLib.TermsOfPurchases;
			Else
				Picture = PictureLib.TermsOfPurchasesAreNotApproved;
			EndIf;
				
			ChoiceData.Add(
				Structure,
				Presentation,
				,
				Picture);
			
		EndDo;
			
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	NewCommand = Catalogs.CounterpartyContracts.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.FunctionalOptions = "UseContractsWithVendors";
	EndIf;
	
	NewCommand = BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.WriteMode = "";
	EndIf;
	
	NewCommand = Documents.PurchaseOrder.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.WriteMode = "";
	EndIf;
	
	NewCommand = Documents.GoodsReceiptForStorage.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.WriteMode = "";
	EndIf;
	
	NewCommand = Documents.VendorInvoice.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.WriteMode = "";
	EndIf;
	
	NewCommand = Documents.VendorPriceList.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.WriteMode = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//     ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Catalog.TermsOfPurchaseFromVendors.Form.ListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Catalogs.TermsOfPurchaseFromVendors))
		And AccessRight("Update", Metadata.Catalogs.TermsOfPurchaseFromVendors)
	    And GetFunctionalOption("UseTermsOfPurchases");
		
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN TermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.NotApproved)
	|				THEN TermsOfPurchases.Ref
	|		END) AS AgreementsWithSuppliersOnApproval,
	|	COUNT(DISTINCT CASE
	|			WHEN TermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.NotApproved)
	|					AND TermsOfPurchases.ValidityStartDate <> DATETIME(1, 1, 1)
	|					AND TermsOfPurchases.ValidityStartDate < &UpdateDate
	|				THEN TermsOfPurchases.Ref
	|			WHEN TermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|					AND TermsOfPurchases.ValidityEndDate <> DATETIME(1, 1, 1)
	|					AND TermsOfPurchases.ValidityEndDate < &UpdateDate
	|				THEN TermsOfPurchases.Ref
	|			WHEN TermsOfPurchases.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|					AND TermsOfPurchases.ValidityStartDate <> DATETIME(1,1,1) AND
	|					TermsOfPurchases.ValidityStartDate > &UpdateDate
	|				THEN TermsOfPurchases.Ref
	|			ELSE NULL
	|		END) AS AgreementsWithSuppliersExpired
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|WHERE
	|	TermsOfPurchases.Status <> VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|	AND TermsOfPurchases.Manager = &User
	|	AND (NOT TermsOfPurchases.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Agreements by suppliers
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "TermsOfPurchaseFromVendors";
	UserTaskParent.Presentation  = NStr("vi = 'Thỏa thuận với nhà cung cấp';
										|ru = 'Соглашения с поставщиками';
										|en = 'Terms of purchase'; fa = 'شرایط خرید';
										|it = 'Accordi con fornitori';
										|pl = 'Zamówienie do dostawców';
										|tr = 'Satın alma koşulları'");
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	
	// AgreementsWithSuppliersOnApproval
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.StatesOfTermsOfPurchases.PendingApproval);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "AgreementsWithSuppliersOnApproval";
	ToDoItem.HasToDoItems       = Result.AgreementsWithSuppliersOnApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thỏa thuận cần thống nhất';
									|ru = 'Соглашения на согласовании';
									|en = 'Agreements pending approval'; fa = 'Agreements pending approval';
									|it = 'Accordi in fase della contrattazione';
									|pl = 'Porozumienia na uzgodnieniu';
									|tr = 'Mutabakat aşamasındaki anlaşmalar'");
	ToDoItem.Count     = Result.AgreementsWithSuppliersOnApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "TermsOfPurchaseFromVendors";
	
	// AgreementsWithSuppliersExpired
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Undefined);
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "AgreementsWithSuppliersExpired";
	ToDoItem.HasToDoItems       = Result.AgreementsWithSuppliersExpired > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thỏa thuận quá hạn';
									|ru = 'Просроченные соглашения';
									|en = 'Overdue agreements'; fa = 'Overdue agreements';
									|it = 'Accordi scaduti';
									|pl = 'Przeterminowane porozumienia';
									|tr = 'Vadesi geçmiş anlaşmalar'");
	ToDoItem.Count     = Result.AgreementsWithSuppliersExpired;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "TermsOfPurchaseFromVendors";
	
	If Result.AgreementsWithSuppliersOnApproval > 0
		Or Result.AgreementsWithSuppliersExpired > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.ActiveVendorRebates.AddReportCommand(
		ReportsCommands, Parameters, "CurrentRebatesOfSuppliersContext");
	If ReportCommand <> Undefined Then
		
		Presentation = NStr("vi = 'Thưởng lũy kế của nhà cung cấp đang có hiệu lực';
							|ru = 'Действующие ретро-бонусы поставщика';
							|en = 'Active vendor rebates'; fa = 'تخفیف‌های حجمی فعال فروشنده';
							|it = 'Действующие ретро-бонусы поставщика';
							|pl = 'Active vendor rebates';
							|tr = 'Sağlayıcının geçerli retro bonusları'");
		ReportCommand.Presentation = Presentation;
		
		ArrayOfBusinessTransactions = RebatesClientServer.BusinessProcurementOperations();
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			ArrayOfBusinessTransactions,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.TermsOfPurchaseFromVendors.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.39";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("963251f7-2e28-4a7b-8737-2887210f3ac4");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.TermsOfPurchaseFromVendors.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Thỏa thuận về điều kiện mua hàng""';
								|ru = 'Обновление справочника ""Соглашения об условиях закупок"":';
								|en = 'Update the ""Terms of purchase"" catalog:'; fa = 'Update the ""Terms of purchase"" catalog:';
								|it = 'Update the ""Terms of purchase"" catalog:';
								|pl = 'Update the ""Terms of purchase"" catalog:';
								|tr = '""Satın alma şart ve hükümleri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin ""Thời hạn giao hàng""';
								|ru = '- Заполнение реквизита ""Срок отгрузки""';
								|en = '- Fill in the ""Shipment date"" attribute'; fa = '- Fill in the ""Shipment date"" attribute';
								|it = '- Fill in the ""Shipment date"" attribute';
								|pl = '- Fill in the ""Shipment date"" attribute';
								|tr = '- ""Sevkiyat süresi"" özniteliğini doldurma'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.TermsOfPurchaseFromVendors.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.TermsOfPurchaseFromVendors.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.TermsOfPurchaseFromVendors.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TermsOfPurchaseFromVendors.Ref AS Ref
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|WHERE
	|	TermsOfPurchaseFromVendors.DeleteDeliveryPeriod <> 0
	|	AND TermsOfPurchaseFromVendors.ShipmentDueDate = 0";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Thỏa thuận về điều kiện mua hàng"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Соглашения об условиях закупок"" по обработчику:';
								|en = 'Cannot process the ""Terms of purchase"" catalog by the handler:'; fa = 'Cannot process the ""Terms of purchase"" catalog by the handler:';
								|it = 'Cannot process the ""Terms of purchase"" catalog by the handler:';
								|pl = 'Cannot process the ""Terms of purchase"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Satın alma şart ve hükümleri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin ""Thời hạn giao hàng""';
								|ru = '- Заполнение реквизита ""Срок отгрузки""';
								|en = '- Fill in the ""Shipment date"" attribute'; fa = '- Fill in the ""Shipment date"" attribute';
								|it = '- Fill in the ""Shipment date"" attribute';
								|pl = '- Fill in the ""Shipment date"" attribute';
								|tr = '- ""Sevkiyat süresi"" özniteliğini doldurma'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	TermsOfPurchaseFromVendors.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|		ON TT.Ref = TermsOfPurchaseFromVendors.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If CatalogObject.ShipmentDueDate = 0 And CatalogObject.DeleteDeliveryPeriod <> 0 Then
					
					CatalogObject.ShipmentDueDate = CatalogObject.DeleteDeliveryPeriod - CatalogObject.DeliveryTime;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndIf
#EndIf
