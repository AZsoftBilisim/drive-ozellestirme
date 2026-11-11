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

// Defines a list of creation commands based on.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	CreationCommand = Documents.CustomerInvoiceServices.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationCommand = Catalogs.CounterpartyContracts.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	CreationCommand = Documents.SalesOrder.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationCommand = Documents.RequestForReturnOfGoodsFromCustomer.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationCommand = Documents.TransferOfGoodsToBailee.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;

	CreationCommand = Documents.GoodsShipmentToCustomer.AddGenerateCommand(
		GenerationCommands);
	
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand,
																	"Standard_",
																	False,
																	DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationCommand = Documents.CustomerInvoice.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationCommand = Documents.CustomerInvoiceServicesAndAssets.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.VisibilityInForms = "ListForm,ListFormOfSpecialTermsOfSales,ItemForm";
		CreationCommand.WriteMode = "";
		AttachableCommands.AddCommandVisibilityCondition(CreationCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	CreationCommand = BusinessProcesses.SaleApproval.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		CreationCommand.FunctionalOptions = "UseInternalApprovalOfTermsOfSales";
		CreationCommand.WriteMode = "";		
		CreationCommand.Presentation = NStr("vi = 'Thống nhất thỏa thuận với khách hàng';
											|ru = 'Согласование соглашения с клиентом';
											|en = 'Approval of customer agreement'; fa = 'تأیید توافق‌نامه مشتری';
											|it = 'Negoziazione dell''accordo con il cliente';
											|pl = 'Uzgadnianie porozumienia z klientem';
											|tr = 'Satış koşullarında mutabakat'");
	EndIf;
	
EndProcedure

// Adds a command to create a directory of agreements by Clients.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Catalogs.TermsOfSale) Then
		
		CustomerAgreementMetadata = Metadata.Catalogs.TermsOfSale;
		 
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = CustomerAgreementMetadata.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(CustomerAgreementMetadata);
		CreateBasedOnCommand.FunctionalOptions = "ToUseTermsOfSales";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

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
	ArrayOfAllProps.Add("CommissionAgentUsesInventoryAccountingByProductBatchID");
	ArrayOfAllProps.Add("PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("MaximumPercentageForManualMarkup");
	ArrayOfAllProps.Add("LimitDiscountAdjustments");
	ArrayOfAllProps.Add("PackageDepositIsRequired");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		ArrayOfOperationDetails.Add("CommissionFeeCalculationMethod");
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("KeepCommissionFee");
		ArrayOfOperationDetails.Add("CommissionAgentUsesInventoryAccountingByProductBatchID");
	ElsIf BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Then
		ArrayOfOperationDetails.Add("PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("MaximumPercentageForManualMarkup");
		ArrayOfOperationDetails.Add("LimitDiscountAdjustments");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
	EndIf;
	
EndProcedure

// Sets the status of agreements with clients
//
// Parameters:
//	Terms1 - Array - array of links to customer agreements
//	Status     - EnumRef.StatusesOfTermsOfSales - the status that will be set for agreements.
//
// Returns:
//  Number - the number of agreements that have the status set.
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
	|	CustomerTermsOfSales.Ref AS Ref,
	|	CustomerTermsOfSales.DeletionMark AS DeletionMark,
	|	CASE
	|		WHEN CustomerTermsOfSales.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches
	|FROM
	|	Catalog.TermsOfSale AS CustomerTermsOfSales
	|WHERE
	|	CustomerTermsOfSales.Ref IN(&ReferencesArrray)");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.SetParameter("Status", Status);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.DeletionMark Then
			
			ErrorText = NStr("vi = 'Thỏa thuận %Terms% đã bị đặt dấu xóa. Không thể thay đổi trạng thái';
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
			
			ErrorText = NStr("vi = 'Thỏa thuận %Terms% đã được gán trạng thái ""%Status%""';
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
							|tr = '%Terms% kaydedilemedi. %ErrorDescription%'");
			ErrorText = StrReplace(ErrorText, "%Terms%", Selection.Ref);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
			
		EndTry
		
	EndDo;
	
	Return ProcessedItemsCount;
	
EndFunction

// This function defines the document details.
//
// Parameters:
//	DocumentRef - CatalogRef.TermsOfSale - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ThisIsTransferToCommission
	|FROM
	|	Catalog.TermsOfSale AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		BusinessOperation = Selection.BusinessOperation;
		ThisIsTransferToCommission = Selection.ThisIsTransferToCommission;
	Else
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
		ThisIsTransferToCommission = False;
	EndIf;
	
	AttributesStructure1 = New Structure("BusinessOperation, ThisIsTransferToCommission",
		BusinessOperation,
		ThisIsTransferToCommission);
	
	Return AttributesStructure1;

EndFunction

// Checks the possibility and sets an individual price list for the object.
// 
// Parameters:
// 	Ref - CatalogRef.TermsOfSale - Link to the price list column.
// 	PricesKind - CatalogRef.TypesOfPrices - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function InstallIPL(Ref, PricesKind) Export
	OperationResult = False;
	
	CatalogObject = Ref.GetObject();
	If ValueIsFilled(CatalogObject.SpecialPriceType) Then
		OperationResult = False;
		
		MessageTextTemplate = NStr("vi = 'Chưa thiết lập dạng giá riêng đối với thỏa thuận ""%ObjectName_1%"" do nguyên nhân: %Cause%';
									|ru = 'Не произведена установка индивидуального виды цен для соглашения ""%ObjectName_1%"" по причине: %Cause%';
									|en = 'The individual price types have not been set for the agreement ""%ObjectName_1%"". Reason: %Cause%'; fa = 'The individual price types have not been set for the agreement ""%ObjectName_1%"". Reason: %Cause%';
									|it = 'Non è stata eseguita l''impostazione di tipo di prezzo individuale per l''accordo ""%ObjectName_1%"" a causa di: %Cause%';
									|pl = 'Nie wykonano ustawienia indywidualnego rodzaju cen dla umowy ""%ObjectName_1%"" z powodu: %Cause%';
									|tr = '""%ObjectName_1%"" anlaşma için özelleştirilmiş fiyat türünün yapılandırılamama nedeni: %Cause%'");
		MessageText = StrReplace(MessageTextTemplate, "%ObjectName_1%", CatalogObject.Description);
		MessageText = StrReplace(MessageText, "%Cause%", "u terms1 already is_specified individual_ kind prices_!");
		
		Raise MessageText;
	Else	
		CatalogObject.SpecialPriceType = PricesKind;
		SetPrivilegedMode(True);
		CatalogObject.Write();
		SetPrivilegedMode(False);
		OperationResult = True;
	EndIf;
	
	Return OperationResult;
EndFunction

// Deletes the individual price list for the item.
// 
// Parameters:
// 	Ref - CatalogRef.TermsOfSale - Link to the price list column.
// Returns:
// 	Boolean - The result of the execution.
Function DeleteIPL(Ref) Export
	OperationResult = False;	
	
	CatalogObject = Ref.GetObject();
	CatalogObject.SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
	SetPrivilegedMode(True);
	CatalogObject.Write();
	SetPrivilegedMode(False);
	
	OperationResult = True;
	
	Return OperationResult;
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

// The commission agent keeps records on the RNPT.
// 
// Parameters:
//  Terms - CatalogRef.TermsOfSale - the agreement under which you need to get the setup.
// 
// Returns:
//  Boolean - The commission agent keeps records on the RNPT
//
Function CommissionAgentUsesInventoryAccountingByProductBatchID(Terms) Export
	
	If Not TypeOf(Terms) = Type("CatalogRef.TermsOfSale") Then
		Return False;
	EndIf;
	
	CommissionAgentUsesInventoryAccountingByProductBatchID =
		Common.ObjectAttributeValue(Terms, "CommissionAgentUsesInventoryAccountingByProductBatchID", True);
	
	If CommissionAgentUsesInventoryAccountingByProductBatchID = Undefined Then
		Return False;
	Else
		Return CommissionAgentUsesInventoryAccountingByProductBatchID;
	EndIf;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(AgreementKindToLimitReadAccess)
	|	AND ValueAllowed(Partner, EmptyRef AS TRUE)
	|	AND ValueAllowed(Warehouse, EmptyRef AS TRUE)
	|	AND ValueAllowed(Organization, EmptyRef AS TRUE)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(AgreementKindToLimitEditAccess)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	AvailableToExternalUsers
	|	AND ValueAllowed(Warehouse, EmptyRef AS TRUE)
	|	AND (Standard_
	|		OR ValueAllowed(ExternalUsersPartners.Ref)
	|		OR ValueAllowed(ExternalUsersContactPersons.Ref))";

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	SalesNotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Sales");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "d0dcb5bd-9406-481c-aa51-f0426398cc6d";
	NewTypeOfAlerts.Description = NStr("vi = 'Thống nhất các thỏa thuận về điều kiện bán hàng';
										|ru = 'Согласование соглашений об условиях продаж';
										|en = 'Terms of sales approval'; fa = 'Terms of sales approval';
										|it = 'Terms of sales approval';
										|pl = 'Terms of sales approval';
										|tr = 'Satış şartlarına ilişkin anlaşmaların mutabakatı'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.TermsOfSale.Templates.Notifications_Approval.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Thống nhất thỏa thuận.';
												|ru = 'Согласовать соглашение.';
												|en = 'Approve terms of sales.';
												|it = 'Approve terms of sales.';
												|pl = 'Approve terms of sales.';
												|tr = 'Anlaşmayı onayla.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Thống nhất các thỏa thuận về điều kiện bán hàng.';
												|ru = 'Согласовать соглашения об условиях продаж.';
												|en = 'Approve terms of sales.';
												|it = 'Approve terms of sales.';
												|pl = 'Approve terms of sales.';
												|tr = 'Satış şartlarına ilişkin anlaşmaları onayla.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "413b40aa-ec43-4c07-a73b-fcc1dafd25a2";
	NewTypeOfAlerts.Description = NStr("vi = 'Ngày hết hiệu lực của các thỏa thuận về điều kiện bán hàng đang đến gần';
										|ru = 'Приближение даты окончания действия соглашений об условиях продаж';
										|en = 'Approach of terms of sales expiration date'; fa = 'Approach of terms of sales expiration date';
										|it = 'Approach of terms of sales expiration date';
										|pl = 'Approach of terms of sales expiration date';
										|tr = 'Satış şartlarına ilişkin anlaşmaların sona erme tarihinin yaklaşması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.TermsOfSale.Templates.Notifications_ExpirationDateIsApproaching.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Kết thúc thời hạn hiệu lực của thỏa thuận [ValidityEndDate].';
												|ru = 'Заканчивается срок действия соглашения [ValidityEndDate].';
												|en = 'The terms of sales are expiring on [ValidityEndDate].';
												|it = 'The terms of sales are expiring on [ValidityEndDate].';
												|pl = 'The terms of sales are expiring on [ValidityEndDate].';
												|tr = 'Anlaşmanın geçerlilik süresi sona eriyor [ValidityEndDate].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Kết thúc thời hạn hiệu lực của thỏa thuận về điều kiện bán hàng.';
												|ru = 'Заканчивается срок действия соглашений об условиях продаж.';
												|en = 'Terms of sales are expiring.';
												|it = 'Terms of sales are expiring.';
												|pl = 'Terms of sales are expiring.';
												|tr = 'Satış şartlarına ilişkin anlaşmanın geçerlilik süresi sona eriyor.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "ed019256-d7ca-4717-991f-62a6eef8f4f1";
	NewTypeOfAlerts.Description = NStr("vi = 'Kết thúc thời hạn hiệu lực của thỏa thuận về điều kiện bán hàng';
										|ru = 'Окончание срока действия соглашений об условиях продаж';
										|en = 'Terms of sales expiration'; fa = 'Terms of sales expiration';
										|it = 'Terms of sales expiration';
										|pl = 'Terms of sales expiration';
										|tr = 'Satış şartlarına ilişkin anlaşmaların geçerlilik süresinin sona ermesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.Catalogs.TermsOfSale.Templates.Notifications_ExpirationDateIsOver.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã kết thúc thời hạn hiệu lực của thỏa thuận [ValidityEndDate].';
												|ru = 'Закончился срок действия соглашения [ValidityEndDate].';
												|en = 'The terms of sales expired on [ValidityEndDate].';
												|it = 'The terms of sales expired on [ValidityEndDate].';
												|pl = 'The terms of sales expired on [ValidityEndDate].';
												|tr = 'Anlaşmanın geçerlilik süresi sona erdi [ValidityEndDate].'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã kết thúc thời hạn hiệu lực của thỏa thuận về điều kiện bán hàng.';
												|ru = 'Закончился срок действия соглашений об условиях продаж.';
												|en = 'Terms of sales expired.';
												|it = 'Terms of sales expired.';
												|pl = 'Terms of sales expired.';
												|tr = 'Satış şartlarına ilişkin anlaşmanın geçerlilik süresi sona erdi.'"; // @NStr-1
	
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
	
	Partner                          = Catalogs.Partners.EmptyRef();
	DocumentDate                    = CurrentSessionDate();
	OnlyStandard                    = False;
	OnlyUsedBySalesRepresentative      = False;
	OnlyTransferOperations           = False;
	SearchString                     = "";
	BusinessOperation            = Undefined;
	ConsignmentSales25            = Undefined;
	ContractsAreUsed = Undefined;
	ShipmentWithDeferredTransferOfTitle25 = Undefined;
	
	If Parameters.Filter.Property("Partner") Then
		Partner = Parameters.Filter.Partner;
	EndIf;
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
		
	If Parameters.Filter.Property("Date") Then
		DocumentDate = BegOfDay(Parameters.Filter.Date);
	EndIf;
		
	If Parameters.Property("OnlyStandard") Then
		OnlyStandard = Parameters.OnlyStandard;
	EndIf;
	
	If Parameters.Property("OnlyUsedBySalesRepresentative") Then
		OnlyUsedBySalesRepresentative = Parameters.OnlyUsedBySalesRepresentative;
	EndIf;
	
	If Parameters.Property("OnlyTransferOperations") Then
		OnlyTransferOperations = Parameters.OnlyTransferOperations;
	EndIf;
	
	SelectionConditionForBusinessOperation = "";
	If Parameters.Filter.Property("BusinessOperation", BusinessOperation) Then
		If TypeOf(BusinessOperation) = Type("EnumRef.BusinessTransactions") Then
			SelectionConditionForBusinessOperation 
				= "AND DocumentCustomerTermsOfSales.BusinessOperation = &BusinessOperation";
		Else
			SelectionConditionForBusinessOperation 
				= "AND DocumentCustomerTermsOfSales.BusinessOperation IN(&BusinessOperation)";
		EndIf;
	EndIf;
	
	If Parameters.Filter.Property("ConsignmentSales25") Then
		ConsignmentSales25 = Parameters.Filter.ConsignmentSales25;
	EndIf;
	
	If Parameters.Property("ShipmentWithDeferredTransferOfTitle25") Then
		ShipmentWithDeferredTransferOfTitle25 = Parameters.ShipmentWithDeferredTransferOfTitle25;
	EndIf;
	
	If ShipmentWithDeferredTransferOfTitle25 = True Then
		ContractsAreUsed = GetFunctionalOption("UseCustomerContracts");
	Else
		Parameters.Filter.Property("ContractsAreUsed", ContractsAreUsed);
	EndIf;
	
	Parameters.Property("SearchString",SearchString);
	
	//The query text contains literals for redefining/substituting &conditioningconversion operations
	Query = New Query("
		|SELECT ALLOWED TOP 51
		|	DocumentCustomerTermsOfSales.Ref          AS Ref,
		|	DocumentCustomerTermsOfSales.Description    AS Description,
		|	DocumentCustomerTermsOfSales.Number           AS Number,
		|	DocumentCustomerTermsOfSales.Date            AS Date,
		|	DocumentCustomerTermsOfSales.Standard_         AS Standard_,
		|
		|	CASE
		|		WHEN
		|			DocumentCustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|			AND DocumentCustomerTermsOfSales.ValidityStartDate <> DATETIME(1,1,1)
		|			AND &DocumentDate <> DATETIME(1,1,1)
		|			AND DocumentCustomerTermsOfSales.ValidityStartDate > &DocumentDate
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS TheValidityPeriodHasNotCome,
		|
		|	CASE
		|		WHEN
		|			DocumentCustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|			AND DocumentCustomerTermsOfSales.ValidityEndDate <> DATETIME(1,1,1)
		|			AND &DocumentDate <> DATETIME(1,1,1)
		|			AND DocumentCustomerTermsOfSales.ValidityEndDate < &DocumentDate
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ValidityPeriodExpired
		|
		|FROM
		|	Catalog.TermsOfSale AS DocumentCustomerTermsOfSales
		|WHERE
		|	NOT DocumentCustomerTermsOfSales.DeletionMark
		|	AND DocumentCustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|	AND (NOT &SelectionByCommission OR DocumentCustomerTermsOfSales.ConsignmentSales25 = &ConsignmentSales25)
		|	AND 
		|	CASE
		|		WHEN &OnlyStandard = TRUE
		|		AND (DocumentCustomerTermsOfSales.Standard_
		|		AND (DocumentCustomerTermsOfSales.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
		|		OR DocumentCustomerTermsOfSales.PartnersSegment IN
		|			(SELECT
		|				SegmentPartners.Segment
		|			FROM
		|				InformationRegister.SegmentPartners AS SegmentPartners
		|			WHERE
		|				SegmentPartners.Partner = &Partner)))
		|		THEN TRUE
		|		
		|		WHEN &OnlyStandard = FALSE
		|		AND (DocumentCustomerTermsOfSales.Standard_
		|		AND (DocumentCustomerTermsOfSales.PartnersSegment = VALUE(Catalog.PartnersSegments.EmptyRef)
		|		OR DocumentCustomerTermsOfSales.PartnersSegment IN
		|			(SELECT
		|				SegmentPartners.Segment
		|			FROM
		|				InformationRegister.SegmentPartners AS SegmentPartners
		|			WHERE
		|				SegmentPartners.Partner = &Partner))
		|			OR
		|				(NOT DocumentCustomerTermsOfSales.Standard_ AND
		|				DocumentCustomerTermsOfSales.Partner = &Partner))
		|		THEN TRUE
		|		
		|		ELSE FALSE
		|	
		|	END
		|	AND
		|	CASE
		|		WHEN &OnlyUsedBySalesRepresentative = TRUE AND
		|			DocumentCustomerTermsOfSales.UsedInSalesRepresentativesWork
		|			THEN TRUE
		|		WHEN &OnlyUsedBySalesRepresentative = FALSE THEN TRUE
		|		ELSE FALSE
		|	END 
		|	AND
		|	CASE
		|		WHEN &OnlyTransferOperations = TRUE AND
		|			(DocumentCustomerTermsOfSales.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|			OR DocumentCustomerTermsOfSales.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|				AND &FilterShipmentWithDeferredTransferOfTitle25
		|				AND DocumentCustomerTermsOfSales.SaleWithDeferredTransferOfTitleIsAllowed
		|				AND DocumentCustomerTermsOfSales.ContractsAreUsed
		|			OR DocumentCustomerTermsOfSales.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) 
		|				AND DocumentCustomerTermsOfSales.ConsignmentSales25) 
		|			THEN TRUE
		|		WHEN &OnlyTransferOperations = FALSE THEN TRUE
		|		ELSE FALSE
		|	END
		|	AND CASE
		|		WHEN &FilterByContract = TRUE
		|				AND DocumentCustomerTermsOfSales.ContractsAreUsed = &ContractsAreUsed
		|			THEN TRUE
		|		WHEN &FilterByContract = FALSE
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|	AND CASE
		|		WHEN &FilterShipmentWithDeferredTransferOfTitle25
		|		AND DocumentCustomerTermsOfSales.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomer))
		|			THEN DocumentCustomerTermsOfSales.SaleWithDeferredTransferOfTitleIsAllowed
		|			AND DocumentCustomerTermsOfSales.ContractsAreUsed
		|		ELSE TRUE
		|	END
		|	AND (DocumentCustomerTermsOfSales.Description LIKE &SearchString ESCAPE ""~""
		|	OR DocumentCustomerTermsOfSales.Number LIKE &SearchString ESCAPE ""~"")
		|	AND &SelectionConditionForBusinessOperation
		|ORDER BY
		|	Standard_ ASC,
		|	ValidityStartDate ASC,
		|	ValidityEndDate ASC
		|");
	
	If Not BusinessOperation = Undefined Then
		Query.Text = StrReplace(Query.Text, "AND &SelectionConditionForBusinessOperation", SelectionConditionForBusinessOperation);
		Query.SetParameter("BusinessOperation", BusinessOperation);
	Else
		Query.Text = StrReplace(Query.Text, "AND &SelectionConditionForBusinessOperation", "");
	EndIf;
	
	Query.SetParameter("Partner",                          Partner);
	Query.SetParameter("DocumentDate",                    BegOfDay(DocumentDate));
	Query.SetParameter("OnlyStandard",                    OnlyStandard);
	Query.SetParameter("OnlyUsedBySalesRepresentative",      OnlyUsedBySalesRepresentative);
	Query.SetParameter("OnlyTransferOperations",           OnlyTransferOperations);
	Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	Query.SetParameter("SelectionByCommission",                  ?(ConsignmentSales25 = Undefined, False, True));
	Query.SetParameter("ConsignmentSales25",            ConsignmentSales25);
	Query.SetParameter("FilterByContract",                  ?(ContractsAreUsed = Undefined, False, True));
	Query.SetParameter("ContractsAreUsed", ContractsAreUsed);
	Query.SetParameter("FilterShipmentWithDeferredTransferOfTitle25",
								ShipmentWithDeferredTransferOfTitle25 = True);
	
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
									|tr = '%Description%(%Date% tarihli %Number%)'");
				Presentation = StrReplace(Presentation,"%Description%", Selection.Description);
				Presentation = StrReplace(Presentation,"%Number%",        Selection.Number);
				Presentation = StrReplace(Presentation,"%Date%",         Format(Selection.Date, "DLF=D"));
				
			ElsIf ValueIsFilled(Selection.Description) And
				ValueIsFilled(Selection.Date) Then
				
				Presentation = NStr("vi = '%Description% (ngày %Date%)';
									|ru = '%Description% (от %Date%)';
									|en = '%Description% (from %Date%)'; fa = '%Description% (from %Date%)';
									|it = '%Description% (dal %Date%)';
									|pl = '%Description% (z dn. %Date%)';
									|tr = '%Description% (%Date% tarihli)'");
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
			
			If Selection.Standard_ Then
				PictureOfAgreement = PictureLib.StandardTermsOfSalesWithCustomer;
			Else
				PictureOfAgreement = PictureLib.SpecialTermsOfSales;
			EndIf;
			
			Structure = New Structure();
			Structure.Insert("Value", Selection.Ref);
			
			If Selection.TheValidityPeriodHasNotCome Then
				Structure.Insert("Warning", NStr("vi = 'Thỏa thuận chưa hết hạn.';
												|ru = 'У соглашения не наступил срок действия.';
												|en = 'The agreement is not within its validity period.'; fa = 'The agreement is not within its validity period.';
												|it = 'L''accordo non è ancora entrato in vigore.';
												|pl = 'Termin wejścia w życie porozumienia jeszcze nie nastąpił.';
												|tr = 'Anlaşmanın süresi henüz dolmamıştır.'"));
			ElsIf Selection.ValidityPeriodExpired Then
				Structure.Insert("Warning", NStr("vi = 'Thỏa thuận đã quá hạn hiệu lực.';
												|ru = 'У соглашения истек срок действия.';
												|en = 'The agreement has expired.'; fa = 'The agreement has expired.';
												|it = 'L''accordo è scaduto.';
												|pl = 'Porozumienie wygasło.';
												|tr = 'Anlaşmanın süresi dolmuştur.'"));
			EndIf;
			
			ChoiceData.Add(
				Structure,
				Presentation,
				,
				PictureOfAgreement);
			
		EndDo;
			
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" Then
		
		If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
			
			DataOfAuthorizedExternalUser = PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser();
			If DataOfAuthorizedExternalUser = Undefined Then
				Return;
			EndIf;
			
			StandardProcessing = False;
			Parameters.Insert("Partner", DataOfAuthorizedExternalUser.Partner);
			Parameters.Insert("ReturnOnlyAgreement", True);
			
			SelectedForm = "DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales";
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If UserRightsCached.ThisIsPartner() Then
		// AGREEMENT WITH THE CLIENT
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CustomerTermsOfSales";
		PrintCommand.Presentation = NStr("vi = 'Thỏa thuận với khách hàng';
										|ru = 'Соглашение с клиентом';
										|en = 'Customer agreement'; fa = 'توافق‌نامه مشتری';
										|it = 'Accordo con il cliente';
										|pl = 'Umowa z klientem';
										|tr = 'Satış koşulları'");
	EndIf;

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CustomerTermsOfSales") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CustomerTermsOfSales", NStr("vi = 'Thỏa thuận với khách hàng';
																												|ru = 'Соглашение с клиентом';
																												|en = 'Customer agreement'; fa = 'توافق‌نامه مشتری';
																												|it = 'Accordo con il cliente';
																												|pl = 'Umowa z klientem';
																												|tr = 'Satış koşulları'"), GeneratePrintForm(ObjectsArray, PrintObjects));
	EndIf;
	
EndProcedure

Function GeneratePrintForm(Terms, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Query = New Query;
	
	If TypeOf(Terms) = Type("Array") Then
		Query.SetParameter("Terms", Terms[Terms.Count() - 1]);
	Else
		Query.SetParameter("Terms", Terms);
	EndIf;
	
	Query.Text =
	"SELECT
	|	TermsOfSale.Description AS Description,
	|	CASE
	|		WHEN TermsOfSale.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			THEN &StringWithoutRestrictions
	|		ELSE PRESENTATION(TermsOfSale.Warehouse)
	|	END AS Warehouse,
	|	TermsOfSale.Number,
	|	TermsOfSale.Date,
	|	TermsOfSale.Organization,
	|	TermsOfSale.Counterparty,
	|	TermsOfSale.ValidityStartDate,
	|	TermsOfSale.ValidityEndDate,
	|	PRESENTATION(TermsOfSale.Currency) AS Currency,
	|	TermsOfSale.PriceIncludesVAT,
	|	TermsOfSale.DeliveryPeriodDays,
	|	TermsOfSale.PaymentSchedule,
	|	CASE
	|		WHEN ISNULL(PaymentSchedules.PaymentMethod, TermsOfSale.PaymentMethod) = VALUE(Enum.PaymentForms.EmptyRef)
	|			THEN &AnyString
	|		ELSE PRESENTATION(ISNULL(PaymentSchedules.PaymentMethod, TermsOfSale.PaymentMethod))
	|	END AS PaymentMethod,
	|	PaymentSchedules.Stages.(
	|		LineNumber,
	|		PaymentOption,
	|		Move,
	|		PaymentPercentage
	|	) AS StagesSchedule,
	|	TermsOfSale.Ref,
	|	TermsOfSale.PaymentScheduleSteps.(
	|		Ref,
	|		LineNumber,
	|		PaymentOption,
	|		Move,
	|		PaymentPercentage
	|	) AS StagesOfAgreement,
	|	TermsOfSale.BusinessOperation,
	|	TermsOfSale.CommissionFeeCalculationMethod,
	|	TermsOfSale.RemunerationPercentage,
	|	TermsOfSale.SaleWithDeferredTransferOfTitleIsAllowed,
	|	TermsOfSale.KeepCommissionFee
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		LEFT JOIN Catalog.PaymentSchedules AS PaymentSchedules
	|		ON TermsOfSale.PaymentSchedule = PaymentSchedules.Ref
	|WHERE
	|	TermsOfSale.Ref = &Terms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup.Presentation AS Presentation
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|			&SliceDate,
	|			Source = &Terms
	|				AND Status = VALUE(Enum.DiscountValidityStatuses.Valid)) AS TheEffectOfDiscountsMarkupsASliceOfTheLast";
	
	Query.SetParameter("StringWithoutRestrictions",NStr("vi = 'không giới hạn';
														|ru = 'без ограничений';
														|en = 'without restrictions'; fa = 'بدون محدودیت';
														|it = 'senza restrizioni';
														|pl = 'bez ograniczeń';
														|tr = 'kısıtlamasız'", Common.DefaultLanguageCode()));
	Query.SetParameter("AnyString",NStr("vi = 'bất kỳ';
										|ru = 'любая';
										|en = 'any'; fa = 'any';
										|it = 'qualsiasi';
										|pl = 'any';
										|tr = 'herhangi'", Common.DefaultLanguageCode()));
	Query.SetParameter("SliceDate", CurrentSessionDate());
	
	FillInTabularDocumentAgreementWithClient(SpreadsheetDocument, Query, PrintObjects);
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other

Procedure FillInDetailsOfHeaderDocumentAgreementWithClient(PrintData, Template, SpreadsheetDocument)
	
	ScopeOfApplication_6                = Template.GetArea("Vendor");
	RegionLegalEntityBuyer         = Template.GetArea("LegalEntityBuyer");
	ScopePeriodOfValidity           = Template.GetArea("ActionPeriod");
	ScopeTypeOfAgreement            = Template.GetArea("AgreementType");
	ScopeOfCommission          = Template.GetArea("CommissionTerms");
	ScopeTermsOfAgreement        = Template.GetArea("TermsOfAgreement__");
	VATArea                      = Template.GetArea("VAT");
	AreaCurrency                   = Template.GetArea("Currency");
	AreaWarehouseTermOfShipment        = Template.GetArea("WarehouseShipmentTime");
	ScopeImplementationWithoutTransferOfOwnership    = Template.GetArea("SaleWithDeferredTransferOfTitle");
	
	// Validity period
	DataStructureValidityPeriod = New Structure("TextValidityPeriod", 
		PrintFormGeneration.GenerateTextValidityPeriod(PrintData.ValidityStartDate,PrintData.ValidityEndDate));
	ScopePeriodOfValidity.Parameters.Fill(DataStructureValidityPeriod);
	SpreadsheetDocument.Put(ScopePeriodOfValidity);
	
	// Our organization 
	InformationAboutCompany = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization,CurrentSessionDate());
	DataStructureProvider = New Structure("SupplierPresentation",
		PrintFormGeneration.OrganizationDescription(InformationAboutCompany));
	ScopeOfApplication_6.Parameters.Fill(DataStructureProvider);
	SpreadsheetDocument.Put(ScopeOfApplication_6);
	
	// The client's counterparty
	If PrintData.Counterparty.IsEmpty() Then
		PresentationLegalEntityBuyer = NStr("vi = 'Không giới hạn';
											|ru = 'Без ограничений';
											|en = 'Without restrictions'; fa = 'بدون محدودیت';
											|it = 'Senza restrizioni';
											|pl = 'Bez ograniczeń';
											|tr = 'Kısıtlamasız'", Common.DefaultLanguageCode());
	Else	
		BuyerInformation  		  = PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty,CurrentSessionDate());
		PresentationLegalEntityBuyer = PrintFormGeneration.OrganizationDescription(BuyerInformation);
	EndIf;
	DataStructureLegalEntityBuyer = New Structure("PresentationLegalEntityBuyer", PresentationLegalEntityBuyer);
	RegionLegalEntityBuyer.Parameters.Fill(DataStructureLegalEntityBuyer);
	SpreadsheetDocument.Put(RegionLegalEntityBuyer);
	
	// Terms of the agreement
	SpreadsheetDocument.Put(ScopeTermsOfAgreement);
	
	TypeOfAgreementToPrint = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Kiểu thỏa thuận: %1';
																							|ru = 'Тип соглашения: %1';
																							|en = 'Terms of sales type: %1'; fa = 'Terms of sales type: %1';
																							|it = 'Тип соглашения: %1';
																							|pl = 'Terms of sales type: %1';
																							|tr = 'Anlaşma türü: %1'",
		Common.DefaultLanguageCode()),
		PrintData.BusinessOperation);
	DataStructureAgreementType = New Structure("AgreementType", TypeOfAgreementToPrint);
	ScopeTypeOfAgreement.Parameters.Fill(DataStructureAgreementType);
	SpreadsheetDocument.Put(ScopeTypeOfAgreement);
	
	If PrintData.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		TextOfCommissionConditions = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Phương pháp hạch toán hoa hồng ký gửi: %1.';
				|ru = 'Способ расчета комиссионного вознаграждения: %1.';
				|en = 'Commission calculation method: %1.'; fa = 'Commission calculation method: %1.';
				|it = 'Metodo di calcolo della bonus sulla commissione: %1.';
				|pl = 'Sposób rozliczania prowizji: %1.';
				|tr = 'Komisyon ücreti hesaplama yöntemi: %1.'", Common.DefaultLanguageCode()), PrintData.CommissionFeeCalculationMethod);
		If PrintData.CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
			TextOfCommissionConditions = TextOfCommissionConditions + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tỷ lệ hoa hồng - %1%.';
					|ru = 'Процент вознаграждения -  %1%.';
					|en = 'Commission percentage - %1%.'; fa = 'Commission percentage - %1%.';
					|it = 'Percentuale di bonus - %1%.';
					|pl = 'Procent wynagrodzenia - %1%.';
					|tr = 'Ücretlendirme yüzdesi -  %1%.'", Common.DefaultLanguageCode()), PrintData.RemunerationPercentage);
			If PrintData.KeepCommissionFee Then
				TextOfCommissionConditions = TextOfCommissionConditions + " " + NStr("vi = 'Hoa hồng giữ lại từ số tiền thanh toán.';
																					|ru = 'Вознаграждение удерживается из суммы оплаты.';
																					|en = 'Commission is deducted from the payment amount.'; fa = 'Commission is deducted from the payment amount.';
																					|it = 'Il bonus viene trattenuto dall''importo del pagamento.';
																					|pl = 'Wynagrodzenie jest potrącane z kwoty płatności.';
																					|tr = 'Ücretlendirme, ödeme tutarından kesilir.'", Common.DefaultLanguageCode())
			EndIf;
		EndIf;
		DataStructureCommissionConditions = New Structure("CommissionTerms", TextOfCommissionConditions);
		ScopeOfCommission.Parameters.Fill(DataStructureCommissionConditions);
		SpreadsheetDocument.Put(ScopeOfCommission);
		
	EndIf;
	
	DataStructureTextCurrency = New Structure("TextCurrency",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tiền tệ của thỏa thuận - %1.';
																		|ru = 'Валюта соглашения - %1.';
																		|en = 'Agreement currency - %1.'; fa = 'Agreement currency - %1.';
																		|it = 'Valuta dell''accordo - %1.';
																		|pl = 'Waluta porozumienia - %1.';
																		|tr = 'Anlaşma para birimi - %1.'", Common.DefaultLanguageCode()),PrintData.Currency));
	AreaCurrency.Parameters.Fill(DataStructureTextCurrency);
	SpreadsheetDocument.Put(AreaCurrency);
	
	VATDataStructure = New Structure("VATText", 
		PrintFormGeneration.GenerateVATText("",PrintData.PriceIncludesVAT));
	VATArea.Parameters.Fill(VATDataStructure);
	SpreadsheetDocument.Put(VATArea);
	
	DataStructureShipmentTime = New Structure("TextWarehouseShipmentTime", 
	          StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Kho bãi: %1. Thời hạn giao hàng (ngày): %2.';
																			|ru = 'Склад: %1. Срок поставки(дней): %2.';
																			|en = 'Warehouse: %1. Delivery period(days): %2.'; fa = 'Warehouse: %1. Delivery period(days): %2.';
																			|it = 'Magazzino: %1. Tempo di consegna(giorni): %2.';
																			|pl = 'Magazyn: %1. Termin dostawy (dni): %2.';
																			|tr = 'Ambar: %1. Teslimat süresi(gün): %2.'", Common.DefaultLanguageCode()),
	                                                                  PrintData.Warehouse,
	                                                                  PrintData.DeliveryPeriodDays));
	AreaWarehouseTermOfShipment.Parameters.Fill(DataStructureShipmentTime);
	SpreadsheetDocument.Put(AreaWarehouseTermOfShipment);
	
	If PrintData.SaleWithDeferredTransferOfTitleIsAllowed Then
		SaleWithDeferredTransferOfTitle = NStr("vi = 'Có thể giao hàng mà chưa chuyển giao quyền sở hữu';
												|ru = 'Возможна отгрузка без перехода права собственности';
												|en = 'Allow shipment with deferred transfer of title of goods'; fa = 'اجازه ارسال با انتقال معوق مالکیت کالا';
												|it = 'La spedizione è possibile senza il passaggio di proprietà';
												|pl = 'Jest możliwa wysyłka bez przeniesienia praw własności';
												|tr = 'Mülkiyet hakkı devri olmadan sevkiyat yapılabilir'", Common.DefaultLanguageCode());
		ShipmentStructureWithoutTransferOfOwnership = 
			New Structure("TextPossibilityOfImplementationWithoutTransferOfOwnership", SaleWithDeferredTransferOfTitle);
	
		ScopeImplementationWithoutTransferOfOwnership.Parameters.Fill(ShipmentStructureWithoutTransferOfOwnership);
		SpreadsheetDocument.Put(ScopeImplementationWithoutTransferOfOwnership);
	EndIf;
	
EndProcedure

Procedure FillOutPaymentScheduleAgreementWithCustomer(PrintData,Template,SpreadsheetDocument)

	AreaPaymentScheduleHeader	= Template.GetArea("PaymentScheduleHeader");
	AreaPaymentStagesHeader 		= Template.GetArea("HeaderOfPaymentStagesPaymentOptionTable");
	AreaFormOfPayment				= Template.GetArea("PaymentMethod");
	PaymentStagesAreaLine		= Template.GetArea("TableRowPaymentStagesPaymentOption");
	AreaBasementPaymentStages		= Template.GetArea("BasementPaymentStages");
	
	// Payment schedule
	SpreadsheetDocument.Put(AreaPaymentScheduleHeader);
	
	DataStructureTextFormOfPayment = New Structure("TextFormOfPayment",
		StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hình thức thanh toán: %1.';
																		|ru = 'Форма оплаты: %1.';
																		|en = 'Payment method: %1.'; fa = 'Payment method: %1.';
																		|it = 'Modalità di pagamento: %1.';
																		|pl = 'Forma płatności: %1.';
																		|tr = 'Ödeme yöntemi: %1.'", Common.DefaultLanguageCode()),PrintData.PaymentMethod));
	AreaFormOfPayment.Parameters.Fill(DataStructureTextFormOfPayment);
	SpreadsheetDocument.Put(AreaFormOfPayment);
	
	SpreadsheetDocument.Put(AreaPaymentStagesHeader);
	
	If ValueIsFilled(PrintData.PaymentSchedule) Then
		PaymentSteps = PrintData.StagesSchedule;
	Else
		PaymentSteps = PrintData.StagesOfAgreement;
	EndIf;
	
	For Each PaymentStage In PaymentSteps.Unload() Do
		FillPropertyValues(PaymentStagesAreaLine.Parameters,PaymentStage);
		SpreadsheetDocument.Put(PaymentStagesAreaLine);
	EndDo;
	
	SpreadsheetDocument.Put(AreaBasementPaymentStages);

EndProcedure

Procedure FillInTabularDocumentAgreementWithClient(SpreadsheetDocument, Query, PrintObjects) Export
	
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	
	PrintData = QueryResult.Select();
	PrintData.Next();
	
	Template = PrintManagement.PrintFormTemplate("Catalog.TermsOfSale.PF_MXL_CustomerTermsOfSales");

	HeaderArea_ = Template.GetArea("Title");

	TitleText = PrintData.Description;
	If Not IsBlankString(PrintData.Number) Then
		TitleText = TitleText + " № " + PrintData.Number;
	EndIf;
	
	If Not PrintData.Date = Date(1,1,1) Then
		TitleText = TitleText + " " + NStr("vi = 'từ';
											|ru = 'от';
											|en = 'dated'; fa = 'مورخ';
											|it = 'del';
											|pl = 'od';
											|tr = 'tarih'", Common.DefaultLanguageCode()) + " " + Format(PrintData.Date,"DLF=DD");
	EndIf;
	
	HeaderDataStructure_1 = New Structure("TitleText", TitleText);
	HeaderArea_.Parameters.Fill(HeaderDataStructure_1);
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, PrintData.Ref);
	SpreadsheetDocument.Put(HeaderArea_);
	
	FillInDetailsOfHeaderDocumentAgreementWithClient(PrintData,Template,SpreadsheetDocument);
	FillOutPaymentScheduleAgreementWithCustomer(PrintData,Template,SpreadsheetDocument);
	FillOutDiscountMarkUpAgreementWithCustomer(QueryResultsArray[1], Template, SpreadsheetDocument)
	
EndProcedure

Procedure FillOutDiscountMarkUpAgreementWithCustomer(PrintData,Template,SpreadsheetDocument)

	GeneralTermsAndConditionsOfDiscounts    = Template.GetArea("TermsOfDiscounts");
	DiscountArea_     = Template.GetArea("DiscountsRow");
	
	DiscountsMarkups = PrintData.Unload();
	
	If DiscountsMarkups.Count() <> 0 Then
		SpreadsheetDocument.Put(GeneralTermsAndConditionsOfDiscounts);
	EndIf;
	For Each DiscountMarkup In DiscountsMarkups Do
		DataStructureDiscountString = New Structure("NameOfDiscount", " • " + DiscountMarkup.Presentation);
		DiscountArea_.Parameters.Fill(DataStructureDiscountString);
		SpreadsheetDocument.Put(DiscountArea_);
	EndDo;
	
EndProcedure

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//     ToDoList - See ToDoListServer.ToDoList
// 
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	FillOutIndividualAgreementsWithClients(ToDoList, CommonQueryParameters);
	FillOutStandardAgreementsWithClients(ToDoList, CommonQueryParameters);
	
EndProcedure

// Parameters:
//     ToDoList - See ToDoListServer.ToDoList
//
Procedure FillOutIndividualAgreementsWithClients(ToDoList, CommonQueryParameters)
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Catalogs.TermsOfSale))
		And AccessRight("Update", Metadata.Catalogs.TermsOfSale)
		And GetFunctionalOption("ToUseTermsOfSales");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.NotApproved)
	|				THEN CustomerTermsOfSales.Ref
	|		END) AS IndividualAgreementsWithClientsOnApproval,
	|	COUNT(DISTINCT CASE
	|	WHEN 
	|		CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.NotApproved)
	|		AND ((CustomerTermsOfSales.ValidityStartDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityStartDate < &UpdateDate)
	|		OR (CustomerTermsOfSales.ValidityEndDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityEndDate < &UpdateDate))
	|	THEN
	|		CustomerTermsOfSales.Ref
	|	// EXPIRED //////////////////////////////////////////////////////
	|	WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|		AND ((CustomerTermsOfSales.ValidityEndDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityEndDate < &UpdateDate))
	|	THEN
	|		CustomerTermsOfSales.Ref
	|	// THE EXPIRATION DATE HAS NOT COME ////////////////////////////////////////////////
	|	WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|		AND ((CustomerTermsOfSales.ValidityStartDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityStartDate > &UpdateDate))
	|	THEN
	|		CustomerTermsOfSales.Ref
	|		END) AS IndividualAgreementsWithCustomersOverdue
	|FROM
	|	Catalog.TermsOfSale AS CustomerTermsOfSales
	|WHERE
	|	CustomerTermsOfSales.Status <> VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|	AND (NOT CustomerTermsOfSales.Standard_)
	|	AND CustomerTermsOfSales.Manager = &User
	|	AND (NOT CustomerTermsOfSales.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Individual agreements by clients
	
	FormName = "Catalog.TermsOfSale.Form.ListFormOfSpecialTermsOfSales";
	
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "IndividualAgreementsWithCustomers";
	UserTaskParent.Presentation  = NStr("vi = 'Thỏa thuận riêng với khách hàng';
										|ru = 'Индивидуальные соглашения с клиентами';
										|en = 'Special terms of sales'; fa = 'شرایط ویژه فروش';
										|it = 'Accordi personali con i clienti';
										|pl = 'Indywidualne umowy z klientami';
										|tr = 'Özelleştirilmiş satış koşulları'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// IndividualAgreementsWithClientsOnApproval
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.StatesOfTermsOfSales.PendingApproval);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Regularity", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "IndividualAgreementsWithClientsOnApproval";
	ToDoItem.HasToDoItems       = Result.IndividualAgreementsWithClientsOnApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thỏa thuận cần thống nhất';
									|ru = 'Соглашения на согласовании';
									|en = 'Agreements pending approval'; fa = 'Agreements pending approval';
									|it = 'Accordi in fase della contrattazione';
									|pl = 'Porozumienia na uzgodnieniu';
									|tr = 'Müzakere aşamasındaki anlaşmalar'");
	ToDoItem.Count     = Result.IndividualAgreementsWithClientsOnApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "IndividualAgreementsWithCustomers";
	
	// IndividualAgreementsWithCustomersOverdue
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Undefined);
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Regularity", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "IndividualAgreementsWithCustomersOverdue";
	ToDoItem.HasToDoItems       = Result.IndividualAgreementsWithCustomersOverdue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thỏa thuận quá hạn';
									|ru = 'Просроченные соглашения';
									|en = 'Overdue agreements'; fa = 'Overdue agreements';
									|it = 'Accordi scaduti';
									|pl = 'Przeterminowane porozumienia';
									|tr = 'Vadesi geçmiş anlaşmalar'");
	ToDoItem.Count     = Result.IndividualAgreementsWithCustomersOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "IndividualAgreementsWithCustomers";
	
	If Result.IndividualAgreementsWithCustomersOverdue > 0
		Or Result.IndividualAgreementsWithClientsOnApproval > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

Procedure FillOutStandardAgreementsWithClients(ToDoList, CommonQueryParameters)
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		CommonQueryParameters.IsFullUser
		Or AccessRight("View", Metadata.Catalogs.TermsOfSale)
		And AccessRight("Update", Metadata.Catalogs.TermsOfSale)
		And GetFunctionalOption("ToUseTermsOfSales");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT CASE
	|			WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.NotApproved)
	|				THEN CustomerTermsOfSales.Ref
	|		END) AS StandardAgreementsWithClientsOnApproval,
	|	COUNT(DISTINCT CASE
	|	WHEN
	|		CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.NotApproved)
	|		AND ((CustomerTermsOfSales.ValidityStartDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityStartDate < &UpdateDate)
	|		OR (CustomerTermsOfSales.ValidityEndDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityEndDate < &UpdateDate))
	|	THEN
	|		CustomerTermsOfSales.Ref
	|	// EXPIRED //////////////////////////////////////////////////////
	|	WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|		AND ((CustomerTermsOfSales.ValidityEndDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityEndDate < &UpdateDate))
	|	THEN
	|		CustomerTermsOfSales.Ref
	|	// THE EXPIRATION DATE HAS NOT COME ////////////////////////////////////////////////
	|	WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|		AND ((CustomerTermsOfSales.ValidityStartDate <> DATETIME(1,1,1) AND
	|		CustomerTermsOfSales.ValidityStartDate > &UpdateDate))
	|	THEN
	|		CustomerTermsOfSales.Ref
	|		END) AS StandardAgreementsWithCustomersOverdue
	|FROM
	|	Catalog.TermsOfSale AS CustomerTermsOfSales
	|WHERE
	|	CustomerTermsOfSales.Status <> VALUE(Enum.StatusesOfTermsOfSales.Closed)
	|	AND CustomerTermsOfSales.Standard_
	|	AND CustomerTermsOfSales.Manager = &User
	|	AND (NOT CustomerTermsOfSales.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Type Agreements by Clients
	
	FormName = "Catalog.TermsOfSale.Form.StandardTermsOfSalesListForm";
	
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "StandardAgreementsWithCustomers";
	UserTaskParent.Presentation  = NStr("vi = 'Thỏa thuận chung với khách hàng';
										|ru = 'Типовые соглашения с клиентами';
										|en = 'Standard terms of sales'; fa = 'شرایط استاندارد فروش';
										|it = 'Contratti tipo con i clienti';
										|pl = 'Typowe umowy z klientami';
										|tr = 'Standart müşteri sözleşmeleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// StandardAgreementsWithClientsOnApproval
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Enums.StatesOfTermsOfSales.PendingApproval);
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Regularity", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "StandardAgreementsWithClientsOnApproval";
	ToDoItem.HasToDoItems       = Result.StandardAgreementsWithClientsOnApproval > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thỏa thuận cần thống nhất';
									|ru = 'Соглашения на согласовании';
									|en = 'Agreements pending approval'; fa = 'Agreements pending approval';
									|it = 'Accordi in fase della contrattazione';
									|pl = 'Porozumienia na uzgodnieniu';
									|tr = 'Mutabakat aşamasındaki anlaşmalar'");
	ToDoItem.Count     = Result.StandardAgreementsWithClientsOnApproval;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "StandardAgreementsWithCustomers";
	
	// StandardAgreementsWithCustomersOverdue
	FilterParameters = New Structure;
	FilterParameters.Insert("State", Undefined);
	FilterParameters.Insert("Relevance", "Overdue1");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Regularity", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "StandardAgreementsWithCustomersOverdue";
	ToDoItem.HasToDoItems       = Result.StandardAgreementsWithCustomersOverdue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Thỏa thuận quá hạn';
									|ru = 'Просроченные соглашения';
									|en = 'Overdue agreements'; fa = 'Overdue agreements';
									|it = 'Accordi scaduti';
									|pl = 'Przeterminowane porozumienia';
									|tr = 'Vadesi geçmiş anlaşmalar'");
	ToDoItem.Count     = Result.StandardAgreementsWithCustomersOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "StandardAgreementsWithCustomers";
	
	If Result.StandardAgreementsWithClientsOnApproval > 0
		Or Result.StandardAgreementsWithCustomersOverdue > 0 Then
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
	
	ReportCommand = Reports.FulfillmentOfRegularConditionsOfTermsOfSales.AddFulfillmentOfTermsOfAgreementsWithClientsCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListFormOfSpecialTermsOfSales";
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	ReportCommand = Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListFormOfSpecialTermsOfSales";
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	ReportCommand = Reports.SaleApprovalResults.AddCustomerAgreementNegotiationResultsCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListFormOfSpecialTermsOfSales";
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand, "Standard_", False, DataCompositionComparisonType.Equal);
	EndIf;
	
	ReportCommand = Reports.SalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,StandardTermsOfSalesListForm,ListFormOfSpecialTermsOfSales";
	EndIf;
	
	ReportCommand = Reports.SalesTermsAndConditions2_5.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,StandardTermsOfSalesListForm,ListFormOfSpecialTermsOfSales";
	EndIf;
	
	ReportCommand = Reports.ActiveRebatesByTermsOfSales.AddReportCommand(
		ReportsCommands,
		"CurrentRetroRebatesByAgreementContext");
	If ReportCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.SaleToCustomer,
			DataCompositionComparisonType.Equal);
		ReportCommand.VisibilityInForms = "ItemForm,ListForm,StandardTermsOfSalesListForm,ListFormOfSpecialTermsOfSales";
		
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

#EndRegion

#EndIf
