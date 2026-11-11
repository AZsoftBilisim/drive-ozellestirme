#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance(); 
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	SetAvailabilityOfClipboardCommands();
	
	If Parameters.Property("HasErrors") And Parameters.HasErrors Then
		For Each CurError In Parameters.ErrorsArray Do
			Common.MessageToUser(
				CurError.Text,
				CurError.DataKey,
				CurError.Field,
				CurError.DataPath);
		EndDo;
	EndIf;
	
	AccountingForLaborCostsByEmployees = ProductionServer.AccountingOfLaborCostsInContextOfEmployeesIsUsed(
		?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.BackflushProduction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.BackflushProduction.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisForm, SetupParameters);
	// End GLAccountSettings
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisForm);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// Standard subsystems.External processing
	// The end of the standard subsystem.External processing
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// Standard subsystems.Commercial equipment
	TMCommonUse.CustomizePeripherals(ThisForm, "ManufacturedProducts");
	TMCommonUse.CustomizePeripherals(ThisForm, "SideAndIntermediateRelease");
	TMCommonUse.CustomizePeripherals(ThisForm, "MaterialsAndWorks");
	// The end of the standard subsystem.Commercial equipment

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// ItemsAndDimensionsSelectionParameters
	ItemsAndDimensionsSelectionParameters = Documents.BackflushProduction.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	SetupParameters = Documents.BackflushProduction.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisForm, SetupParameters);
	// End GLAccountSettings
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	If Not ValueIsFilled(Object.Ref)
		And UseInternalSubcontracting
		And Not DisplayInternalProcessingOfCurrentDocument Then
		
		DisplayGiversInCostGroup                  = DisplayInternalProcessing;
		DisplayInternalProcessingOfCurrentDocument = DisplayInternalProcessing;
		Items.DisplayInternalProcessing.Check = DisplayInternalProcessingOfCurrentDocument;
		
		ConfigureCostGroupingElements(False);
		
	EndIf;
	
	If RightToReadSubstitutes
	   And ShowAnalogues
	   And Object.GroupCosts <> Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		NotePresenceOfAnalogues();
		ConfiguringDependentFormElements(ThisObject, "ShowAnalogues");
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UpdateOnOpening Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// Standard subsystems.Commercial equipment
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// The end of the standard subsystem.Commercial equipment
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.GroupCosts =
			PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified") Then
		Object.SideAndIntermediateRelease.Clear();
		Object.MaterialsAndWorks.Clear();
		Object.LaborCosts.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// GLAccountSettings
	GLAccountSettingsServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End GLAccountSettings
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FillInParametersForSpecifyingSeries();
	SetVisibilityOfSeriesElements();
	
	FillInServiceDetailsOfForm();
	
	UpdateListOfCostGroups();
	ConfigureCostGroupingElements(False);
	ConfiguringDependentFormElements(ThisObject);
	SetProductGroupHeaders(ThisObject);
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	// End ItemsAndDimensionsSelectionParameters
	
	// GLAccountSettings
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	// End GLAccountSettings
		

	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	

	Notify("Write_BackflushProduction");
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	Var CurrentOperation1;
	
	If ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.EnterCostShare" Then
		
		CurrentData = CurrentItem.CurrentData;
		If CurrentData = Undefined Then 
			Return;
		EndIf;
		
		Modified = True;
		ProcessingInputOfFractionOfCost(CurrentItem, CurrentData, ValueSelected);
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		CurrentData = Items[ValueSelected.TSName].CurrentData;
		
		ProductsClient.ProcessSeriesIndication(
			ThisObject,
			SeriesSpecificationParameters[ValueSelected.TSName],
			ValueSelected,
			CurrentData);
		
		If Not CurrentData = Undefined Then
			
			If ValueSelected.TSName = "ManufacturedProducts"
				And (Object.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.ByProducts")
					Or Object.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments")) Then
				
				StringFields = "CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series";
				StringFields = "CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series, InternalSubcontracting, MaterialProviderCompany";
				CurDataStructure = New Structure(StringFields);
				
				FillPropertyValues(CurDataStructure, CurrentData);
				AddChangeCostGroup(CurDataStructure);
				
				CurrentData.CostGroupNumber = CurDataStructure.CostGroupNumber;
				CurrentData.ExpenseGroup = CurDataStructure.ExpenseGroup;
			
			EndIf;
			
			If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentData.Products, "Series", Object.Date) Then
				
				StructureOfActions = New Structure;
				
				If ValueSelected.TSName = "ManufacturedProducts" Then
					StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
				EndIf;
				
				If (ValueSelected.TSName = "ManufacturedProducts" And UseTargetCost)
					Or ValueSelected.TSName = "SideAndIntermediateRelease" Then
					
					ParametersStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
					ParametersStructure.Insert("PriceKind", Object.PriceKind);
					StructureOfActions.Insert("FillInSalePrice", ParametersStructure);
					StructureOfActions.Insert("RecalculateAmount", "Count");
					
				EndIf;
				
				If Not StructureOfActions.Count() = 0 Then
					BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.SubstitutionOfMaterialsWithAlternativeMaterials" Then
		
		Replace_With_Analogues(ValueSelected.AddressInStorage);
		
	ElsIf TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("CurrentOperation1", CurrentOperation1) Then
		
		If Upper(CurrentOperation1) = Upper("AddItemsFromSalesOrderGoodsIssue") Then
			ProductSelectionProcessing(ValueSelected.AddressInStorage);
		EndIf;
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter);
			
			If Items.GroupPages.CurrentPage = Items.GroupMaterialsAndWorks Then
				TSName = "MaterialsAndWorks";
			ElsIf TypeOf(CurrentItem) = Type("FormTable")
				And Items.GroupPages.CurrentPage = Items.GroupFinishedProducts Then
				
				TSName = CurrentItem.Name;
				
			Else
				TSName = "ManufacturedProducts";
			EndIf;
			
			ProcessBarcodes(TSName, BarcodeData_5);
			
		EndIf;
		
	EndIf;
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(Parameter.TSName, BarcodeData_5);
		
	EndIf;
	// End StandardSubsystems.Peripherals
	

	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrectionClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	UpdateIssueForActivities();
	EstablishUseOfPlannedValue();
	ConfiguringDependentFormElements(ThisObject, "Date");
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If Not CompanyBeforeChange = Object.Organization Then
		OrganizationWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	If UseInternalSubcontracting Then
		FillInDetailsOfOrganization();
	EndIf;
	
	If Object.InternalSubcontracting
		And ValueIsFilled(Object.Organization) Then
		
		If Object.MaterialProviderCompany = Object.Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người nhận gia công không thể trùng với doanh nghiệp-người đặt gia công.';
								|ru = 'Организация-переработчик не может совпадать с организацией-давальцем.';
								|en = 'Subcontractor company and the material provider company cannot be the same.'; fa = 'Subcontractor company and the material provider company cannot be the same.';
								|it = 'Организация-переработчик не может совпадать с организацией-давальцем.';
								|pl = 'Subcontractor company and the material provider company cannot be the same.';
								|tr = 'Fason üretici iş yeri ile tedarikçi iş yeri aynı olamaz.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
		If Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProviderCompany) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp nhận gia công không được phép có quan hệ với doanh nghiệp đặt gia công theo cấu trúc tổ chức.';
								|ru = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|en = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.'; fa = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|it = 'Организация-переработчик не должна быть взаимосвязана с организацией-давальцем по организационной структуре.';
								|pl = 'Subcontractor company must not be interrelated to the material provider company by the organizational structure.';
								|tr = 'Fason üretici iş yeri, iş yeri yapısı bakımından tedarikçi iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
		If ValueIsFilled(Object.MaterialProviderCompany)
			And Not LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.MaterialProviderCompany) Then
			
			MessageText = NStr("vi = 'Tiền tệ kế toán tài chính của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.';
								|ru = 'Валюты регламентированного учета организации-переработчика и организации-давальца должны совпадать.';
								|en = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.'; fa = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.';
								|it = 'Валюты регламентированного учета организации-переработчика и организации-давальца должны совпадать.';
								|pl = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.';
								|tr = 'Fason üretici iş yerinin ve tedarikçi iş yerinin yerel muhasebe para birimleri aynı olmalıdır.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
		If ValueIsFilled(Object.MaterialProviderCompany)
			And Not RegistrationCountry = Common.ObjectAttributeValue(Object.MaterialProviderCompany, "RegistrationCountry") Then
			
			MessageText = NStr("vi = 'Quốc gia đăng ký của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.';
								|ru = 'Страны регистрации организации-переработчика и организации-давальца должны совпадать.';
								|en = 'Countries of residence of the subcontractor company and the material provider company must be the same.'; fa = 'Countries of residence of the subcontractor company and the material provider company must be the same.';
								|it = 'Страны регистрации организации-переработчика и организации-давальца должны совпадать.';
								|pl = 'Countries of residence of the subcontractor company and the material provider company must be the same.';
								|tr = 'Fason üretici iş yeri ve tedarikçi iş yerinin kayıtlı olduğu ülkeler aynı olmalıdır.'");
			Common.MessageToUser(MessageText,, "Organization", "Object");
			
			Object.Organization = CompanyBeforeChange;
			
			Return;
			
		EndIf;
		
	EndIf;
	UpdateIssueForActivities();
	If ValueIsFilled(Object.Organization) Then
		TextOwnerProcessor = StrTemplate(NStr("vi = 'Người nhận gia công: %1';
												|ru = 'Переработчик: %1';
												|en = 'Subcontractor: %1'; fa = 'Subcontractor: %1';
												|it = 'Переработчик: %1';
												|pl = 'Subcontractor: %1';
												|tr = 'Fason üretici: %1'"), Object.Organization);
	Else
		TextOwnerProcessor = "";
	EndIf;
	
	CheckOwnerOfProducts();
	EstablishUseOfPlannedValue();
	ConfiguringDependentFormElements(ThisObject, "Organization");
	
	CompanyBeforeChange = Object.Organization;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure GroupCostsOnChange(Item)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Event.GroupCostsOnChange");
	// End StandardSubsystems.PerformanceMeasurement
	
	If GroupCostsBeforeChange = Object.GroupCosts Then
		Return;
	EndIf;
	
	SetProductGroupHeaders(ThisObject);
	GroupingCostsForChangesOnServer();
	
EndProcedure

&AtServer
Procedure GroupingCostsForChangesOnServer()
	
	If Not ValueIsFilled(Object.GroupCosts) Then
		Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument;
	EndIf;
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument Then
		CostGroupIndex = 1;
	Else
		CostGroupIndex = 0;
	EndIf;
	If Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument
		And Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		Object.InternalSubcontracting  = False;
		Object.MaterialProviderCompany     = Catalogs.Companies.EmptyRef();
		CompanyGiverBeforeChange = Object.MaterialProviderCompany;
	Else
		For Each RowData In Object.ManufacturedProducts Do
			RowData.InternalSubcontracting = False;
			RowData.MaterialProviderCompany    = Catalogs.Companies.EmptyRef();
		EndDo;
	EndIf;
	ListOfGroups.Clear();
	MaximumNumberOfCostGroup = 0;
	
	For Each RowData In Object.ManufacturedProducts Do
		AddChangeCostGroup(RowData);
	EndDo;
	
	For Each RowData In Object.SideAndIntermediateRelease Do
		RowData.CostGroupNumber = CostGroupIndex;
		RowData.ExpenseGroup = "";
		RowData.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		RowData.InternalSubcontracting = False;
		RowData.MaterialProviderCompany = Catalogs.Companies.EmptyRef();
		RowData.ProductOwner = Catalogs.Companies.EmptyRef();
		RowData.TextOwnerGiver = "";
	EndDo;
	
	For Each RowData In Object.MaterialsAndWorks Do
		RowData.CostGroupNumber = CostGroupIndex;
		RowData.ExpenseGroup = "";
		RowData.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndDo;
	
	For Each RowData In Object.LaborCosts Do
		RowData.CostGroupNumber = CostGroupIndex;
		RowData.ExpenseGroup = "";
	EndDo;
	
	DistributeBatchesOfProductsByCostGroups("ManufacturedProducts");
	DistributeBatchesOfProductsByCostGroups("SideAndIntermediateRelease");
	
	FillInStatusesForSpecifyingSeriesServer("ManufacturedProducts");
	FillInStatusesForSpecifyingSeriesServer("SideAndIntermediateRelease");
	FillInStatusesForSpecifyingSeriesServer("MaterialsAndWorks");
	
	UpdateListOfCostGroups();
	
	ConfigureCostGroupingElements(False);
	ConfiguringDependentFormElements(ThisObject, "GroupCosts");
	
	GroupCostsBeforeChange = Object.GroupCosts;
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProducts
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.EmptyRef();
	ElsIf Not ValueIsFilled(Object.MethodOfAllocatingFinishedProductCosts) Then
		Object.MethodOfAllocatingFinishedProductCosts = Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares;
	EndIf;
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
	FillInStatusesForSpecifyingSeriesServer("ManufacturedProducts");
	If RightToReadSubstitutes
		And ShowAnalogues
		And Object.GroupCosts <> Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		NotePresenceOfAnalogues();
	EndIf;
EndProcedure

&AtClient
Procedure InternalSubcontractingOnChange(Item)
	If Not Object.InternalSubcontracting Then
		Object.MaterialProviderCompany     = Undefined;
		CompanyGiverBeforeChange = Object.MaterialProviderCompany;
	EndIf;
	
	DisplayInternalProcessingOfCurrentDocument = Object.InternalSubcontracting;
	
	TransferInternalProcessingOfHeaderToProductTable();
	
	ConfiguringDependentFormElements(ThisObject, "InternalSubcontracting");
	Return;
	
EndProcedure

&AtClient
Procedure MaterialProviderCompanyOnChange(Item)
	If ValueIsFilled(Object.MaterialProviderCompany)
		And Object.MaterialProviderCompany = Object.Organization Then
		
		MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công không thể trùng với doanh nghiệp-người nhận gia công.';
							|ru = 'Организация-давалец не может совпадать с организацией-переработчиком.';
							|en = 'Material provider company and the subcontractor company cannot be the same.'; fa = 'Material provider company and the subcontractor company cannot be the same.';
							|it = 'Организация-давалец не может совпадать с организацией-переработчиком.';
							|pl = 'Material provider company and the subcontractor company cannot be the same.';
							|tr = 'Tedarikçi iş yeri ile fason üretici iş yeri aynı olamaz.'");
		CommonClient.MessageToUser(MessageText,, "MaterialProviderCompany", "Object");
		
		Object.MaterialProviderCompany = CompanyGiverBeforeChange;
		
		Return;
		
	EndIf;
	
	If Not CompanyGiverBeforeChange = Object.MaterialProviderCompany Then
		CompanyGivesGiverWhenChangeIsMadeOnServer();
	EndIf;
	Return;
	
EndProcedure

&AtServer
Procedure CompanyGivesGiverWhenChangeIsMadeOnServer()
	
	If ValueIsFilled(Object.MaterialProviderCompany)
		And Not Object.MaterialProviderCompany = Object.Organization
		And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.MaterialProviderCompany) Then
		
		MessageText = NStr("vi = 'Doanh nghiệp đặt gia công không được phép có quan hệ với doanh nghiệp nhận gia công theo cấu trúc tổ chức.';
							|ru = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
							|en = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
							|it = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
							|pl = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
							|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılı olmamalıdır.'");
		Common.MessageToUser(MessageText,, "MaterialProviderCompany", "Object");
		
		Object.MaterialProviderCompany = CompanyGiverBeforeChange;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(Object.MaterialProviderCompany)
		And Not LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.MaterialProviderCompany) Then
		
		MessageText = NStr("vi = 'Tiền tệ kế toán tài chính của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.';
							|ru = 'Валюты регламентированного учета организации-переработчика и организации-давальца должны совпадать.';
							|en = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.'; fa = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.';
							|it = 'Валюты регламентированного учета организации-переработчика и организации-давальца должны совпадать.';
							|pl = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.';
							|tr = 'Fason üretici iş yerinin ve tedarikçi iş yerinin yerel muhasebe para birimleri aynı olmalıdır.'");
		Common.MessageToUser(MessageText,, "MaterialProviderCompany", "Object");
		
		Object.MaterialProviderCompany = CompanyGiverBeforeChange;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(Object.MaterialProviderCompany)
		And Not RegistrationCountry = Common.ObjectAttributeValue(Object.MaterialProviderCompany, "RegistrationCountry") Then
		
		MessageText = NStr("vi = 'Quốc gia đăng ký của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.';
							|ru = 'Страны регистрации организации-переработчика и организации-давальца должны совпадать.';
							|en = 'Countries of residence of the subcontractor company and the material provider company must be the same.'; fa = 'Countries of residence of the subcontractor company and the material provider company must be the same.';
							|it = 'Страны регистрации организации-переработчика и организации-давальца должны совпадать.';
							|pl = 'Countries of residence of the subcontractor company and the material provider company must be the same.';
							|tr = 'Fason üretici iş yeri ve tedarikçi iş yerinin kayıtlı olduğu ülkeler aynı olmalıdır.'");
		Common.MessageToUser(MessageText,, "MaterialProviderCompany", "Object");
		
		Object.MaterialProviderCompany = CompanyGiverBeforeChange;
		
		Return;
		
	EndIf;
	
	TransferInternalProcessingOfHeaderToProductTable();
	ConfiguringDependentFormElements(ThisObject, "MaterialProviderCompany");
	
	CompanyGiverBeforeChange = Object.MaterialProviderCompany;
	
EndProcedure

&AtServer
Procedure TransferInternalProcessingOfHeaderToProductTable()
	
	For Each CurrentData In Object.ManufacturedProducts Do
		
		CurrentData.InternalSubcontracting = Object.InternalSubcontracting;
		CurrentData.MaterialProviderCompany    = Object.MaterialProviderCompany;
		
		AddChangeCostGroup(CurrentData);
		
	EndDo;
	
EndProcedure
&AtClient
Procedure DepartmentOnChange(Item)
	
	If Not DepartmentBeforeChange = Object.Department Then
		DepartmentOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()
	
	TSName = "ManufacturedProducts";
	
	StructureOfActions = New Structure;
	
	AddRecipientActionsToStructure(TSName, ThisObject, StructureOfActions);
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True);
	
	BatchProcessingOfTablePartServer.TreatTS(Object[TSName], StructureOfActions);
	
	DepartmentBeforeChange = Object.Department;
	If RightToReadSubstitutes
		And ShowAnalogues
		And Object.GroupCosts <> Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		NotePresenceOfAnalogues();
	EndIf;
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	If ValueIsFilled(Object.PriceKind) 
		And (Object.SideAndIntermediateRelease.Count()
			Or Object.ManufacturedProducts.Count()) Then
		
		CallbackDescription = New CallbackDescription("PriceKindOnChangeCompletion", ThisForm);
		QueryText = NStr("vi = 'Điền lại giá hàng hóa?';
						|ru = 'Перезаполнить цены изделий?';
						|en = 'Refill product prices?'; fa = 'Refill product prices?';
						|it = 'Ricompilare i prezzi dei prodotti?';
						|pl = 'Wypełnić ponownie ceny wyrobów?';
						|tr = 'Nihai ürün fiyatları yeniden doldurulsun mu?'");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PriceKindOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		// StandardSubsystems.PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"Document.BackflushProduction.Form.DocumentForm.Event.PriceKindOnChangeCompletion");
		// End StandardSubsystems.PerformanceMeasurement
		
		PricesCalculated = FillInPricesByPriceKindServer();
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Item.Currency.OnChange");
	
	If PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "SideAndIntermediateRelease")
		Or PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency, "ManufacturedProducts") Then
		
		CurrencyOnChangeServer();
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
		
	EndIf;
	
	DocumentCurrency = Object.Currency;
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer()
	
	OldCurrency				= DocumentCurrency;
	NewCurrency					= Object.Currency;
	DocumentDate				= ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	StructureOfOldCurrencyRates	= ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate);
	StructureOfNewCurrencyRates	= ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate);
	
	// Recalculate the price
	For Each CurRow In Object.SideAndIntermediateRelease Do
		CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(CurRow.Price,
			StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	EndDo;

	For Each CurRow In Object.ManufacturedProducts Do
		CurRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(CurRow.Price,
			StructureOfOldCurrencyRates, StructureOfNewCurrencyRates);
	EndDo;
	
	// Recalculate the amount
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.SideAndIntermediateRelease, StructureOfActions, CachedValues);
	BatchProcessingOfTablePartServer.TreatTS(Object.ManufacturedProducts, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	StructureOfActions = New Structure;
	
	
	InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	
	ValuesInCache = Undefined;
	If ValueIsFilled(StructureOfActions) Then
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	TSStrings = LinesOfBusinessServer.WhenChangingDirectionOfActivity(ThisObject);
	If ValueIsFilled(StructureOfActions) Then
	
		ProcessedLinesOutputProducts = New Array;
		ProcessedStringsByProducts = New Array;
		
		For Each CurRow In TSStrings Do
			
			If Not Object.ManufacturedProducts.IndexOf(CurRow) = -1 Then
				ProcessedLinesOutputProducts.Add(CurRow);
			EndIf;
			
			If Not Object.SideAndIntermediateRelease.IndexOf(CurRow) = -1 Then
				ProcessedStringsByProducts.Add(CurRow);
			EndIf;
			
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ProcessedStringsByProducts,
			StructureOfActions,
			Object.SideAndIntermediateRelease,
			ValuesInCache);
		
		
	EndIf;
	For Each CurRow In TSStrings Do
		If Object.ManufacturedProducts.IndexOf(CurRow) = -1 Then
			Continue;
		EndIf;
		AddChangeCostGroup(CurRow);
	EndDo;
	FillParameters = ParametersAndDirectionOfActivity(Object);
	FillInActivityDirectionInTable("ManufacturedProducts", FillParameters);
	
	If RightToReadSubstitutes
		And ShowAnalogues
		And Object.GroupCosts <> Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		NotePresenceOfAnalogues();
	EndIf;
	UpdateIssueForActivities();
	
EndProcedure

&AtClient
Procedure ProductionIssueForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure MethodOfAllocatingFinishedProductCostsOnChange(Item)
	
	MethodForAllocatingCostsForOutputProductsWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure MethodForAllocatingCostsForOutputProductsWhenChangingOnServer()
	
	CostAllocationParametersStructure = Documents.BackflushProduction.CostAllocationParameters(Object);
	CostAllocationParameters = New FixedStructure(CostAllocationParametersStructure);
	
	ProductionServer.CalculateFractionOfCost(Object, CostAllocationParameters);
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
		
		DocumentCorrectionClient.StringFixHandlingNavigationLinks(
			ThisObject, FormattedStringURL, StandardProcessing);
			
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtClient
Procedure ManufacturedProductsOnChange(Item)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Event.ManufacturedProductsOnChange");
	// End StandardSubsystems.PerformanceMeasurement
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If (Not Object.Patch
			Or Not Object.CorrectionSavesProductionLots)
		And Not CurrentData = Undefined Then
		
		StringFields = "CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series";
		StringFields = "CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series, InternalSubcontracting, MaterialProviderCompany";
		CurDataStructure = New Structure(StringFields);
		
		FillPropertyValues(CurDataStructure, CurrentData);
		AddChangeCostGroup(CurDataStructure);
		
		CurrentData.CostGroupNumber = CurDataStructure.CostGroupNumber;
		CurrentData.ExpenseGroup = CurDataStructure.ExpenseGroup;
		
	ElsIf Object.Patch
		And Object.CorrectionSavesProductionLots Then
		SetDefaultCostGroupNumber("ManufacturedProducts");
	EndIf;
	
	SetProductGroupHeaders(ThisObject, "ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items["ManufacturedProductsSeries"] 
		Or Field = Items["ManufacturedProductsBatchesIndicationStatus"] Then
		SeriesSelectionTable("ManufacturedProducts", Field, Item, StandardProcessing);
	ElsIf Field = Items.ManufacturedProductsTransactionRecordingPresentation Then
		GLAccountSettingsClient.OnClick(ThisForm, Field, StandardProcessing);
	ElsIf (Field = Items.ManufacturedProductsCostSharePercentage
			Or Field = Items.ManufacturedProductsThereAreErrorsOfFillingInCostShare)
		And Object.MethodOfAllocatingFinishedProductCosts <> PredefinedValue("Enum.MethodsOfCostAllocatingOnProductCosts.ByCostShares") Then
		StandardProcessing = False;
		CurrentData = Items.ManufacturedProducts.CurrentData;
		OpenCostShareEntryForm(CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionProcessingTable("ManufacturedProducts", ValueSelected);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If NewRow Then
		
		FillInDefaultWarehouseInLine(ThisObject, CurrentData, "Recipient");
		CurrentData.InternalSubcontracting = Object.InternalSubcontracting;
		CurrentData.MaterialProviderCompany    = Object.MaterialProviderCompany;
	EndIf;
	
	If Copy Then
		CurrentData.RowCode = 0;
	EndIf;
	
	//Setting up accounting accounts 
	If NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
	RestrictRecipientType("ManufacturedProducts", CurrentData);
	
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.ManufacturedProducts");
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.ManufacturedProducts, ThisObject);
	
	UpdateCachedValuesToAccountForSeries("ManufacturedProducts", Item, CachedValues, Copy);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	If NewRow Then
	
		CurrentData = Items.ManufacturedProducts.CurrentData;
		
		If Not ValueIsFilled(CurrentData.Purpose) Then
		
			StructureOfActions = New Structure;
			
			AddActionFillActivityDirection(StructureOfActions, Object);
			
			ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();	
			
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, ValuesInCache);	
		
		EndIf;
		
	EndIf;
	TableAtEndOfEditing("ManufacturedProducts", Item);
	
	If ProductionClient.ItIsNecessaryToCalculatePercentageOfDistributionOfCostsForOutputProducts(
			Item, CostAllocationParameters, ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject), NewRow) Then
		
		Groups = Undefined;
		
		CurrentData = Items.ManufacturedProducts.CurrentData;
		If Not CurrentData = Undefined Then
			Groups = New Array;
			Groups.Add(ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject).CostGroupNumber);
			Groups.Add(CurrentData.CostGroupNumber);
		EndIf;
		
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsBeforeDeleteRow(Item, Cancel)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Event.ManufacturedProductsBeforeDeleteRow");
	// End StandardSubsystems.PerformanceMeasurement
	
	OutputItemsBeforeDeletingOnServer();
	UpdateCachedValuesToAccountForSeries("ManufacturedProducts", Item, CachedValues, False);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsAfterDeleteRow(Item)
	
	AfterDeletingTSLines("ManufacturedProducts", Item);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	TableCostGroupStartOfSelection("ManufacturedProducts", False);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsExpenseGroupClearing(Item, StandardProcessing)
	
	TableCostGroupCleaning("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsProductsOnChange(Item)
	
	TableProductsWhenChanged("ManufacturedProducts", "Recipient");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCharacteristicOnChange(Item)
	
	TableCharacteristicsWhenChanging("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsNumberOfPackagesOnChange(Item)
	
	TableNumberOfPackagesWhenChanged("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPackageOnChange(Item)
	
	PackingTableWhenChanging("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPriceOnChange(Item)
	
	CurrentRow = Items.ManufacturedProducts.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSumOnChange(Item)
	
	CurrentRow = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesOnChange(Item)
	
	TableSeriesWhenChanged("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("ManufacturedProducts", Item.EditText, Items.ManufacturedProducts.CurrentData);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsPurposeOnChange(Item)
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	StructureOfActions = New Structure;
	
	
	AddActionFillActivityDirection(StructureOfActions, Object);

	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, ValuesInCache);
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDirectionOfProductionIssueOnChange(Item)
	
	TableDirectionOfReleaseWhenChanging("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDirectionOfProductionIssueStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableReleaseDirectionStartOfSelection("ManufacturedProducts", StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsRecipientOnChange(Item)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse") Then
		TableWarehouseWhenModified("ManufacturedProducts", "Recipient", CurrentData);
	ElsIf CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		TableItemOfExpenditureInCaseOfChange(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsRecipientStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		TableExpenseItemStartOfSelection(Item, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableCostAnalyticsStartOfSelection(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters,
													Waiting, StandardProcessing)
	
	TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
																StandardProcessing)
	
	TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OutputFinishedProductsInternalProcessingOnChange(Item)
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	If Not CurrentData.InternalSubcontracting Then
		CurrentData.MaterialProviderCompany = Undefined;
	EndIf;
	Return;
	
EndProcedure

&AtClient
Procedure OutputFinishedProductsCompanyGiverOnChange(Item)
	CurrentData = Items.ManufacturedProducts.CurrentData;
	
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items.ManufacturedProducts, ThisObject);
	
	If CurrentData.MaterialProviderCompany = Object.Organization Then
		
		MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công không thể trùng với doanh nghiệp-người nhận gia công.';
							|ru = 'Организация-давалец не может совпадать с организацией-переработчиком.';
							|en = 'Material provider company and the subcontractor company cannot be the same.'; fa = 'Material provider company and the subcontractor company cannot be the same.';
							|it = 'Организация-давалец не может совпадать с организацией-переработчиком.';
							|pl = 'Material provider company and the subcontractor company cannot be the same.';
							|tr = 'Tedarikçi iş yeri ile fason üretici iş yeri aynı olamaz.'");
		Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
		CommonClient.MessageToUser(MessageText,, Field, "Object");
		
		CurrentData.MaterialProviderCompany = LineCache.MaterialProviderCompany;
		
		Return;
		
	EndIf;
	
	OutputProductsOfCompanyGiverWhenChangingOnServer(CurrentData.GetID(), LineCache);
	Return;
	
EndProcedure

&AtServer
Procedure OutputProductsOfCompanyGiverWhenChangingOnServer(CurID_, LineCache)
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurID_);
	
	If ValueIsFilled(CurrentData.MaterialProviderCompany)
		And Not CurrentData.MaterialProviderCompany = Object.Organization
		And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, CurrentData.MaterialProviderCompany) Then
		
		MessageText = NStr("vi = 'Doanh nghiệp đặt gia công có quan hệ với doanh nghiệp nhận gia công theo cấu trúc tổ chức.';
							|ru = 'Организация-давалец взаимосвязана с организацией-переработчиком по организационной структуре.';
							|en = 'Material provider company is interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company is interrelated to the subcontractor company by the organizational structure.';
							|it = 'Организация-давалец взаимосвязана с организацией-переработчиком по организационной структуре.';
							|pl = 'Material provider company is interrelated to the subcontractor company by the organizational structure.';
							|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılıdır.'");
		Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
		Common.MessageToUser(MessageText,, Field, "Object");
		
		CurrentData.MaterialProviderCompany = LineCache.MaterialProviderCompany;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.MaterialProviderCompany)
		And Not LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(CurrentData.MaterialProviderCompany) Then
		
		MessageText = NStr("vi = 'Tiền tệ kế toán tài chính của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.';
							|ru = 'Валюты регламентированного учета организации-переработчика и организации-давальца должны совпадать.';
							|en = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.'; fa = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.';
							|it = 'Валюты регламентированного учета организации-переработчика и организации-давальца должны совпадать.';
							|pl = 'Local accounting currencies of the subcontractor company and the material provider company must be the same.';
							|tr = 'Fason üretici iş yerinin ve tedarikçi iş yerinin yerel muhasebe para birimleri aynı olmalıdır.'");
		Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
		Common.MessageToUser(MessageText,, Field, "Object");
		
		CurrentData.MaterialProviderCompany = LineCache.MaterialProviderCompany;
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(CurrentData.MaterialProviderCompany)
		And Not RegistrationCountry = Common.ObjectAttributeValue(CurrentData.MaterialProviderCompany, "RegistrationCountry") Then
		
		MessageText = NStr("vi = 'Quốc gia đăng ký của doanh nghiệp nhận gia công và doanh nghiệp đặt gia công phải trùng nhau.';
							|ru = 'Страны регистрации организации-переработчика и организации-давальца должны совпадать.';
							|en = 'Countries of residence of the subcontractor company and the material provider company must be the same.'; fa = 'Countries of residence of the subcontractor company and the material provider company must be the same.';
							|it = 'Страны регистрации организации-переработчика и организации-давальца должны совпадать.';
							|pl = 'Countries of residence of the subcontractor company and the material provider company must be the same.';
							|tr = 'Fason üretici iş yeri ve tedarikçi iş yerinin kayıtlı olduğu ülkeler aynı olmalıdır.'");
		Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", CurrentData.LineNumber, "MaterialProviderCompany");
		Common.MessageToUser(MessageText,, Field, "Object");
		
		CurrentData.MaterialProviderCompany = LineCache.MaterialProviderCompany;
		
		Return;
		
	EndIf;
	
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersSideAndIntermediateRelease

&AtClient
Procedure SideAndIntermediateReleaseOnChange(Item)
	
	SetDefaultCostGroupNumber("SideAndIntermediateRelease");
	SetProductGroupHeaders(ThisObject, "SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items["SideAndIntermediateReleaseSeries"] 
		Or Field = Items["SideAndIntermediateReleaseBatchesIndicationStatus"] Then
		SeriesSelectionTable("SideAndIntermediateRelease", Field, Item, StandardProcessing);
	ElsIf Field = Items.SideAndIntermediateReleaseTransactionRecordingPresentation Then
		GLAccountSettingsClient.OnClick(ThisForm, Field, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionProcessingTable("SideAndIntermediateRelease", ValueSelected);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If NewRow Then
		FillInDefaultWarehouseInLine(ThisObject, CurrentData, "Recipient");
		StructureOfActions = New Structure;
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	
	RestrictRecipientType("SideAndIntermediateRelease", CurrentData);
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.SideAndIntermediateRelease");
	
	UpdateCachedValuesToAccountForSeries("SideAndIntermediateRelease", Item, CachedValues, Copy);
	FillInSelectionListOfProductOwners(ThisObject);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	TableAtEndOfEditing("SideAndIntermediateRelease", Item);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseBeforeDeleteRow(Item, Cancel)
	
	UpdateCachedValuesToAccountForSeries("SideAndIntermediateRelease", Item, CachedValues, False);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseAfterDeleteRow(Item)
	AfterDeletingTSLines("SideAndIntermediateRelease", Item);
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableCostGroupStartOfSelection("SideAndIntermediateRelease", False);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseExpenseGroupClearing(Item, StandardProcessing)
	
	TableCostGroupCleaning("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseProductsOnChange(Item)
	
	TableProductsWhenChanged("SideAndIntermediateRelease", "Recipient");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseCharacteristicOnChange(Item)
	
	TableCharacteristicsWhenChanging("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseNumberOfPackagesOnChange(Item)
	
	TableNumberOfPackagesWhenChanged("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePackageOnChange(Item)
	
	PackingTableWhenChanging("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesOnChange(Item)
	
	TableSeriesWhenChanged("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("SideAndIntermediateRelease", Item.EditText, Items.SideAndIntermediateRelease.CurrentData);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePurposeOnChange(Item)
	
	StructureOfActions = New Structure;
	
	InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	
	If ValueIsFilled(StructureOfActions) Then
		
		CurrentData = Items.SideAndIntermediateRelease.CurrentData;
		
		ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, ValuesInCache);
		
	EndIf;
	Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleasePriceOnChange(Item)
	
	CurrentRow = Items.SideAndIntermediateRelease.CurrentData;

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseSumOnChange(Item)
	
	CurrentRow = Items.SideAndIntermediateRelease.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceByAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDirectionOfProductionIssueStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableReleaseDirectionStartOfSelection("SideAndIntermediateRelease", StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDirectionOfProductionIssueOnChange(Item)
	
	TableDirectionOfReleaseWhenChanging("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseRecipientOnChange(Item)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse") Then
		TableWarehouseWhenModified("SideAndIntermediateRelease", "Recipient", CurrentData);
	ElsIf CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		TableItemOfExpenditureInCaseOfChange(Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseRecipientStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		TableExpenseItemStartOfSelection(Item, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableCostAnalyticsStartOfSelection(Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters,
													Waiting, StandardProcessing)
	
	TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
															StandardProcessing)
	
	TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtClient
Procedure MaterialsAndWorksOnChange(Item)
	
	SetDefaultCostGroupNumber("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSelection(Item, RowSelected, Field, StandardProcessing)
	
	If (Field = Items["MaterialsAndWorksSeries"] 
			Or Field = Items["MaterialsAndWorksBatchesIndicationStatus"]) Then
		SeriesSelectionTable("MaterialsAndWorks", Field, Item, StandardProcessing);
	
	ElsIf Field = Items.MaterialsAndWorksThereAreSubstituteMaterials And Not ReadOnly Then
		
		StandardProcessing = False;
		OpenSelectionOfAnalogues();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionProcessingTable("MaterialsAndWorks", ValueSelected);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	
	If NewRow Then
		FillInDefaultWarehouseInLine(ThisForm, CurrentData, "Warehouse");
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorks, ThisObject);
	UpdateCachedValuesToAccountForSeries("MaterialsAndWorks", Item, CachedValues, Copy);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	TableAtEndOfEditing("MaterialsAndWorks", Item);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksBeforeDeleteRow(Item, Cancel)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.MaterialsAndWorks, ThisObject);
	UpdateCachedValuesToAccountForSeries("MaterialsAndWorks", Item, CachedValues, False);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksAfterDeleteRow(Item)
	
	MaterialsAndWorksAfterDeletionOnServer();
	
	 Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableCostGroupStartOfSelection("MaterialsAndWorks", False);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksExpenseGroupClearing(Item, StandardProcessing)
	
	TableCostGroupCleaning("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksProductsOnChange(Item)
	
	TableProductsWhenChanged("MaterialsAndWorks", "Warehouse");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCharacteristicOnChange(Item)
	
	TableCharacteristicsWhenChanging("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	TableNumberOfPackagesWhenChanged("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPackageOnChange(Item)
	
	PackingTableWhenChanging("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesOnChange(Item)
	
	TableSeriesWhenChanged("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries("MaterialsAndWorks", Item.EditText, Items.MaterialsAndWorks.CurrentData);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksWarehouseOnChange(Item)
	
	CurrentData = Items.MaterialsAndWorks.CurrentData;
	TableWarehouseWhenModified("MaterialsAndWorks", "Warehouse", CurrentData);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsOnChange(Item)
	
	SetDefaultCostGroupNumber("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If Copy Then
		CurrentData.RowCode = 0;
	EndIf;
	
	If NewRow And Not Copy Then
		CurrentData.Performer = PredefinedValue("Catalog.Persons.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsDepartmentOnChange(Item)
	LaborCostsAreDeterminedWhenChangingOnServer();
EndProcedure

&AtClient
Procedure LaborCostsExpenseGroupStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableCostGroupStartOfSelection("LaborCosts", False);
	
EndProcedure

&AtClient
Procedure LaborCostsExpenseGroupClearing(Item, StandardProcessing)
	
	TableCostGroupCleaning("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerOnChange(Item)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	If ValueIsFilled(CurrentData.Performer)
		And Not Object.ReferenceOrderForLaborCosts Then
		Object.ReferenceOrderForLaborCosts = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	CallbackDescription = New CallbackDescription("PerformerStartChoiceCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		CurrentData.Department,
		CurrentData.Performer,
		Object.Date,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure PerformerStartChoiceCompletion(Result, Var_Parameters) Export
	
	CurrentData = Items.LaborCosts.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(Result) Then
		CurrentData.Performer = Result;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LaborCostsPerformerAutoComplete(Item, Text, ChoiceData, DataGetParameters,
											Waiting, StandardProcessing)
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		CurrentData = Items.LaborCosts.CurrentData;
		FilterParameters = New Structure("Organization,Department,Date");
		FilterParameters.Organization = Object.Organization;
		FilterParameters.Department = CurrentData.Department;
		FilterParameters.Date = Object.Date;
		PerformerGettingSelectionData(ChoiceData, Text, FilterParameters);
	EndIf;
EndProcedure

&AtClient
Procedure LaborCostsPerformerTextEditEnd(Item, Text, ChoiceData, DataGetParameters,
													StandardProcessing)
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		CurrentData = Items.LaborCosts.CurrentData;
		FilterParameters = New Structure("Organization,Department,Date");
		FilterParameters.Organization = Object.Organization;
		FilterParameters.Department = CurrentData.Department;
		FilterParameters.Date = Object.Date;
		PerformerGettingSelectionData(ChoiceData, Text, FilterParameters);
	EndIf;
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsAreCommon

&AtClient
Procedure SelectionProcessingTable(TSName, ValueSelected)
	
	TableProcessingSelectionSelectionOnServer(ValueSelected, TSName);
	
EndProcedure

&AtServer
Procedure TableProcessingSelectionSelectionOnServer(ValueSelected, TSName)

	If TypeOf(ValueSelected) = Type("Array") Then
		GoodsList = ValueSelected;
	Else
		GoodsList = New Array;
		GoodsList.Add(ValueSelected);
	EndIf;
	
	ObjectTable = Object[TSName]; // FormDataCollection
	RowsArray = New Array;
	RowsToProcess = New Array;
	For Each RowOfProduct In GoodsList Do
		
		CurrentRow = ObjectTable.Add();
		CurrentRow.Products = RowOfProduct;
		If TSName = "ManufacturedProducts" Then
			CurrentRow.InternalSubcontracting = Object.InternalSubcontracting;
			CurrentRow.MaterialProviderCompany    = Object.MaterialProviderCompany;
		EndIf;
		RowsArray.Add(CurrentRow.GetID());
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True, TSName = "MaterialsAndWorks");
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	EndIf;
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable,
		CachedValues);
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		
		If TSName = "ManufacturedProducts" Then
			KTCHPath = "Object.ManufacturedProducts";
		Else
			KTCHPath = "Object.SideAndIntermediateRelease";
		EndIf;
		
		For Each CurrentRow In RowsToProcess Do
			
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, KTCHPath);
			
			If TSName = "ManufacturedProducts" Then
				AddChangeCostGroup(CurrentRow);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

&AtClient
Procedure SeriesSelectionTable(TSName, Field, Item, StandardProcessing)
	
	CurrentData = Items[TSName].CurrentData;
	
	If CurrentData.BatchesIndicationStatus > 0
		And CurrentData.BatchesIndicationStatus <= 11 Then
		StandardProcessing = False;
		OpenSelectionOfSeries(TSName, Field.EditText);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableAtEndOfEditing(TSName, Item)
	
	CurrentData = Items[TSName].CurrentData;
	
	AdditionalParameters = New Structure;
	If TSName = "MaterialsAndWorks" Then
		FormEventsClient.WhenChangingElement(ThisObject, Items[TSName], AdditionalParameters);
	EndIf;
	
	UpdateSeriesStatuses = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters[TSName]);
	
	If UpdateSeriesStatuses Or AdditionalParameters.Property("ServerCallRequired__") Then
		TableAtEndOfEditingOnServer(
			AdditionalParameters.Property("ServerCallRequired__"),
			SeriesSpecificationParameters[TSName],
			?(UpdateSeriesStatuses, CurrentData.GetID(), Undefined),
			CachedValues);
	EndIf;
	
	If UpdateSeriesStatuses Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(
			Item, CachedValues, SeriesSpecificationParameters[TSName]);
	EndIf;
	
EndProcedure

&AtServer
Procedure TableAtEndOfEditingOnServer(Val UpdateTable, Val SeriesSpecificationParameters, Val IDCurrentRow, CachedValues)
	
	If UpdateTable Then
		FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	EndIf;
	
	If IDCurrentRow <> Undefined Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableCostGroupStartOfSelection(TSName, GroupProcessing)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng mà nhóm chi phí sẽ được điền.';
							|ru = 'Необходимо выбрать строки, для которых будет заполнена группа затрат.';
							|en = 'Select the lines for which a cost group will be populated.'; fa = 'Select the lines for which a cost group will be populated.';
							|it = 'È necessario selezionare le righe per le quali sarà compilato il gruppo delle spese.';
							|pl = 'Należy wybrać wiersze, dla których będzie wypełniona grupa kosztów.';
							|tr = 'Maliyet grubunun doldurulacağı satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("GroupCosts", Object.GroupCosts);
	FormParameters.Insert("CostGroupNumber", Items[TSName].CurrentData.CostGroupNumber);
	FormParameters.Insert("CostGroupStorageAddress", CostGroupStorageAddress());
	FormParameters.Insert("DisplayGiversInCostGroup", DisplayGiversInCostGroup);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("TSName",              TSName);
	NotificationParameters.Insert("GroupProcessing", GroupProcessing);
	
	CallbackDescription = New CallbackDescription("TableCostGroupSelection", ThisObject, NotificationParameters);
	OpenForm("Document.BackflushProduction.Form.SelectCostGroup", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TableCostGroupSelection(ClosingResult, NotificationParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	TableCostGroupSelectionATServer(ClosingResult, NotificationParameters)
	
EndProcedure

&AtServer
Procedure TableCostGroupSelectionATServer(ClosingResult, NotificationParameters)
	
	CostGroupNumber		= ClosingResult.CostGroupNumber;
	ExpenseGroup			= ClosingResult.ExpenseGroup;
	LineOfBusiness	= ClosingResult.LineOfBusiness;
	InternalSubcontracting	= ClosingResult.InternalSubcontracting;
	MaterialProviderCompany		= ClosingResult.MaterialProviderCompany;
	SelectedRows = Items[NotificationParameters.TSName].SelectedRows;
	TabularSection   = Object[NotificationParameters.TSName];
	RowsArray      = New Array;
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		
		CurrentData.CostGroupNumber			= CostGroupNumber;
		CurrentData.ExpenseGroup				= ExpenseGroup;
		If NotificationParameters.TSName = "ManufacturedProducts"
			Or NotificationParameters.TSName = "SideAndIntermediateRelease" Then
			CurrentData.InternalSubcontracting	= InternalSubcontracting;
			CurrentData.MaterialProviderCompany	= MaterialProviderCompany;
		EndIf;
		
		If NotificationParameters.TSName = "SideAndIntermediateRelease" Then
			
			CurrentData.ProductOwner = CurrentData.MaterialProviderCompany;
			
			If CurrentData.InternalSubcontracting
				And ValueIsFilled(CurrentData.MaterialProviderCompany) Then
				CurrentData.TextOwnerGiver = StrTemplate(NStr("vi = 'Người đặt gia công: %1';
																|ru = 'Давалец: %1';
																|en = 'Material provider: %1'; fa = 'Material provider: %1';
																|it = 'Давалец: %1';
																|pl = 'Material provider: %1';
																|tr = 'Tedarikçi: %1'"), CurrentData.MaterialProviderCompany);
			Else
				CurrentData.TextOwnerGiver = "";
			EndIf;
			
		EndIf;
		If Not NotificationParameters.TSName = "LaborCosts" Then
			
			CurrentData.LineOfBusiness = LineOfBusiness;
			RowsArray.Add(CurrentData);
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(RowsArray) Then
		If NotificationParameters.TSName = "SideAndIntermediateRelease" Then
			StructureOfActions = New Structure;
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
			BatchProcessingOfTablePartServer.ProcessTSStrings(RowsArray, StructureOfActions, TabularSection);
		EndIf;
		FillInStatusesForSpecifyingSeriesServer(NotificationParameters.TSName, RowsArray);
		
	EndIf;
	
	If NotificationParameters.TSName = "MaterialsAndWorks" Then
		
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableCostGroupCleaning(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.CostGroupNumber = 0;
	CurrentData.ExpenseGroup = "";
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		CurrentData.InternalSubcontracting = Undefined;
		CurrentData.MaterialProviderCompany    = Undefined;
	EndIf;
	
	If TSName = "SideAndIntermediateRelease" Then
		CurrentData.ProductOwner       = Undefined;
		CurrentData.TextOwnerGiver  = "";
	EndIf;
	If Not TSName = "LaborCosts" Then
		CurrentData.LineOfBusiness = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure TableProductsWhenChanged(TSName, NameWarehouse)
	
	CurrentRow = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions,, TSName = "MaterialsAndWorks");
	AddWarehouseActionsToStructure(TSName, ThisObject, StructureOfActions);
	AddShopPantryActionsToStructure(TSName, StructureOfActions,, TSName = "MaterialsAndWorks");
	AddActionsToStructureToFillInArticleAndAnalytics(TSName, ThisObject, StructureOfActions, CurrentRow);
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisObject, StructureOfActions);
	
	AddSeriesActionsToStructure(StructureOfActions, CurrentRow[NameWarehouse], SeriesSpecificationParameters[TSName]);
	
	If TSName = "ManufacturedProducts" Then
		StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
			Object, CurrentRow, BOMSelectionParameters);
		StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		RestrictRecipientType(TSName, CurrentRow);
	EndIf;
	
	If TSName = "MaterialsAndWorks" Then
		
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableCharacteristicsWhenChanging(TSName)
	
	CurrentRow = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfSpecificationFilling = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
			Object, CurrentRow, BOMSelectionParameters);
		StructureOfActions.Insert("CheckFillSpecification", StructureOfSpecificationFilling);
		StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
	EndIf;
	
	StructureOfActions.Insert(
		"CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName,
		TSName));

	If (TSName = "ManufacturedProducts" And UseTargetCost)
		Or TSName = "SideAndIntermediateRelease" Then
		
		ParametersStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
		ParametersStructure.Insert("PriceKind", Object.PriceKind);
		StructureOfActions.Insert("FillInSalePrice", ParametersStructure);
		StructureOfActions.Insert("RecalculateAmount", "Count");
	
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If TSName = "MaterialsAndWorks" Then
		
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TableNumberOfPackagesWhenChanged(TSName)
	
	CurrentRow = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisForm, StructureOfActions);
	
	If TSName = "SideAndIntermediateRelease" Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PackingTableWhenChanging(TSName)
	
	CurrentRow = Items[TSName].CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisForm, StructureOfActions);
	
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("RecalculateCostShare", CostAllocationParameters);
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableSeriesWhenChanged(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value						= CurrentData.Series;
	ValueSelected.CurrentRowID	= CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(
		ThisForm,
		SeriesSpecificationParameters[TSName],
		ValueSelected,
		CurrentData);
	
	StructureOfActions = New Structure;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentData.Products, "Series", Object.Date) Then
		
		If TSName = "ManufacturedProducts" Then
				StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
		EndIf;
		
		If (TSName = "ManufacturedProducts" And UseTargetCost)
			Or TSName = "SideAndIntermediateRelease" Then
			
			ParametersStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
			ParametersStructure.Insert("PriceKind", Object.PriceKind);
			StructureOfActions.Insert("FillInSalePrice", ParametersStructure);
			StructureOfActions.Insert("RecalculateAmount", "Count");
			
		EndIf;
		
	EndIf;
	
	If Not StructureOfActions.Count() = 0 Then
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure TableReleaseDirectionStartOfSelection(TSName, StandardProcessing)
	
	CurrentData = Items[TSName].CurrentData;
	FillReleaseDirectionSelectionList(TSName, CurrentData);
	
EndProcedure

&AtClient
Procedure TableDirectionOfReleaseWhenChanging(TSName)
	
	CurrentData = Items[TSName].CurrentData;
	
	If TSName = "ManufacturedProducts" Then
		RecipientElementName = "ManufacturedProductsRecipient";
	Else
		RecipientElementName = "SideAndIntermediateReleaseRecipient";
	EndIf;
	
	If Not ValueIsFilled(CurrentData.DirectionOfProductionIssue) Then
		CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
	EndIf;
	
	StructureOfActions = New Structure;
	AddRecipientActionsToStructure(TSName, ThisObject, StructureOfActions);
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	RestrictRecipientType(TSName, CurrentData);
	
	If CurrentData.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		CurrentData.Purpose = Undefined;
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[RecipientElementName]);
	GLAccountSettingsClientServer.WhenChangingAccountAvailabilityDetailsInLine(ThisObject, CurrentData, "Object." + TSName);
	
EndProcedure

&AtClient
Procedure TableWarehouseWhenModified(TSName, NameWarehouse, CurrentData)
	
	StructureOfActions = New Structure;
	AddSeriesActionsToStructure(StructureOfActions, CurrentData[NameWarehouse], SeriesSpecificationParameters[TSName]);
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure TableExpenseItemStartOfSelection(Item, StandardProcessing)
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	// End ItemsAndDimensionsSelectionParameters
	
EndProcedure

&AtClient
Procedure TableItemOfExpenditureInCaseOfChange(Item)
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	// End ItemsAndDimensionsSelectionParameters
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsStartOfSelection(Item, StandardProcessing)
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	// End ItemsAndDimensionsSelectionParameters
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsAutoSelection(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		DataGetParameters,
		StandardProcessing);
	// End ItemsAndDimensionsSelectionParameters
	
EndProcedure

&AtClient
Procedure TableCostAnalyticsEndOfTextEntry(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	// ItemsAndDimensionsSelectionParameters
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(
		ThisObject,
		Item,
		Text,
		ChoiceData,
		DataGetParameters,
		StandardProcessing);
	// End ItemsAndDimensionsSelectionParameters
	
EndProcedure

&AtServer
Procedure CalculatePercentageOfCostAllocationForOutputProducts(Groups = Undefined)
	
	ProductionServer.CalculatePercentageOfCostAllocationForOutputProducts(Object, CostAllocationParameters, Groups);
	
EndProcedure

&AtServer
Function ParametersOfCostShareEntryForm_(CurDataId)
	
	FormParameters = ProductionServer.ParametersOfCostShareEntryForm(Object, CostAllocationParameters, CurDataId);
	Return FormParameters;
	
EndFunction

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
												Var_URL = Undefined,
												StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

&AtServer
Procedure Attachable_ExecuteOverriddenCommandOnServer(AdditionalParameters) Export
	FormEvents.ExecuteOverridableCommand(ThisObject, AdditionalParameters);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region CommandHandlersOutputItems

&AtClient
Procedure ManufacturedProductsPickUpProducts(Command)
	
	OpensGoodsSelection("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsFillTheWarehouse(Command)
	FillInTheWarehouse("ManufacturedProducts", "Recipient");
EndProcedure

&AtClient
Procedure OutputItemsFillInTheExpenseItem(Command)
	FillInExpenseItem("ManufacturedProducts", "Recipient")
EndProcedure

&AtClient
Procedure OutputItemsFillCostGroup(Command)
	
	TableCostGroupStartOfSelection("ManufacturedProducts", True);
	
EndProcedure

&AtClient
Procedure ManufacturedProductsImportDataFromPDT(Command)
	
	GetDataFromTSD("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure RoundTheOutputProductsToTheWholePackage(Command)
	
	RoundToTheWholePackage("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure FinishedProductsSearchByBarcodeExecute(Command)
	
	SearchByBarcodeExecute("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsGetWeight(Command)
	
	GetWeight("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsInsertRows(Command)
	
	GetLinesFromClipboard("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure ManufacturedProductsCopyLines(Command)
	
	CopyTSLines("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputItemsSplitLine(Command)
	
	BreakTSString("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputProductsSpecifyTheSeries(Command)
	
	OpenSelectionOfSeries("ManufacturedProducts");
	
EndProcedure

&AtClient
Procedure OutputProductsFillInTheSpecification(Command)
	
	If Items.ManufacturedProducts.SelectedRows.Count() = 0 Then
		
		ShowMessageBox( ,NStr("vi = 'Không có hàng được chọn trong bảng. Chọn các dòng để điền vào thuộc tính ""Bảng kê chi tiết các nguồn lực sản xuất""';
								|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения реквизита ""Спецификация""';
								|en = 'No lines are selected in the table. Select lines to fill in the BOM attribute'; fa = 'No lines are selected in the table. Select lines to fill in the BOM attribute';
								|it = 'Non ci sono righe selezionate nella tabella. Selezionare le righe per compilare il requisito ""Specifica""';
								|pl = 'Brak wydzielonych wierszy w tabeli. Zaznacz wiersze do wypełnienia atrybutu ""Спецификация""';
								|tr = 'Belirtilen satırlar tabloda bulunmamaktadır. ""Ürün Reçetesi"" özniteliklerinin doldurulması için satırları belirtin'"));
		Return;
		
	EndIf;
	
	OutputProductsFillInTheSpecificationServer(Items.ManufacturedProducts.SelectedRows);
	
EndProcedure

&AtClient
Procedure AddOutputProductsAccordingToSpecification(Command)
	
	If Items.ManufacturedProducts.SelectedRows.Count() = 0 Then
		
		ShowMessageBox( ,NStr("vi = 'Trong bảng không có các dòng được chọn. Hãy chọn các dòng để điền phần bảng';
								|ru = 'В таблице отсутствуют выделенные строки. Выделите строки для заполнения табличной части';
								|en = 'No selected rows in the table. Select rows to fill the table'; fa = 'No selected rows in the table. Select rows to fill the table';
								|it = 'Non ci sono righe selezionate nella tabella. Selezionare le righe per compilare la parte tabulare';
								|pl = 'W tabeli nie ma wybranych wierszy. Wybierz wiersze do wypełnienia sekcji tabelarycznej';
								|tr = 'Tabloda belirtilen satır bulunmamaktadır. Tablo bölümlerinin doldurulması için satırları belirtin'"));
		Return;
		
	EndIf;
	
	AddOutputProductsAccordingToSpecificationServer(Items.ManufacturedProducts.SelectedRows);
EndProcedure

&AtClient
Procedure OutputProductsFillInPricesByPriceType(Command)
	
	ClearMessages();
	
	PricesCalculated = FillInPricesByPriceKindServer("ManufacturedProducts");
	
	If PricesCalculated Then
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputProductsFillInThePricesAccordingToTheCalculation(Command)
	CurrentData = Items.ManufacturedProducts.CurrentData;
	If CurrentData = Undefined Then
		Return
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowsIDs", 
		TMCommonUseClientServer.Array(CurrentData.GetID(),
			False));

	FormParameters = New Structure;
	FilterStructure1 = New Structure();
	FilterStructure1.Insert("Date", Object.Date);
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("ProductionDispatcherBusinessUnit", Object.Department);
	FilterStructure1.Insert("Product", CurrentData.Products);
	CostObjects = New Array();
	If ValueIsFilled(CurrentData.BillOfMaterials) Then
		CostObjects.Add(CurrentData.BillOfMaterials);
	EndIf;
	FilterStructure1.Insert("CostObjects", CostObjects);
	FilterStructure1.Insert("DisableSelectionByCostObjects", True);
	FilterStructure1.Insert("Characteristic", CurrentData.Characteristic);
	FilterStructure1.Insert("Purpose", CurrentData.Purpose);
	FormParameters.Insert("FilterStructure1", FilterStructure1);
	
	FormParameters.Insert("State", 
		PredefinedValue("Enum.StatesOfStandardCostEstimateCalculation.Calculated"));
	
	OpenForm("Document.StandardCosting2_2.Form.ChoiceForm", FormParameters,,,,, 
		New CallbackDescription("CompletionOfPlanningCalculationSelection", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	Return;
			
EndProcedure

&AtClient
Procedure CompletionOfPlanningCalculationSelection(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillInPlanningCalculationsAndPricesOnServer(AdditionalParameters.RowsIDs, 
		Result);
		
EndProcedure
#EndRegion

#Region CommandHandlersByProducts

&AtClient
Procedure ByProductsFillTheWarehouse(Command)
	FillInTheWarehouse("SideAndIntermediateRelease", "Recipient");
EndProcedure

&AtClient
Procedure ByProductsFillInTheExpenseItem(Command)
	FillInExpenseItem("SideAndIntermediateRelease", "Recipient");
EndProcedure

&AtClient
Procedure ByProductsPickUpProducts(Command)
	
	OpensGoodsSelection("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseImportDataFromPDT(Command)
	
	GetDataFromTSD("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure RoundOffTheByProductsToTheWholePackage(Command)
	
	RoundToTheWholePackage("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsBarcodeSearchExecute(Command)
	
	SearchByBarcodeExecute("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure SideAndIntermediateReleaseGetWeight(Command)
	
	GetWeight("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsInsertRows(Command)
	
	GetLinesFromClipboard("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsCopyLines(Command)
	
	CopyTSLines("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsSplitString(Command)
	
	BreakTSString("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure AddByProductsAccordingToTheSpecification(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Command.AddByProductsAccordingToTheSpecification");
	// End StandardSubsystems.PerformanceMeasurement
	
	AddAccordingToSpecificationOnServer("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillInTheCostGroup(Command)
	
	TableCostGroupStartOfSelection("SideAndIntermediateRelease", True);
	
EndProcedure

&AtClient
Procedure ByProductsFillOutTheCalculationArticle(Command)
	
	FillInTheCostingItem("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillInPricesByPriceType(Command)
	
	ClearMessages();
	
	PricesCalculated = FillInPricesByPriceKindServer("SideAndIntermediateRelease");
	
	If PricesCalculated Then
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, Object.PriceKind);
	EndIf;
	
EndProcedure

&AtClient
Procedure ByProductsSpecifyTheSeries(Command)
	
	OpenSelectionOfSeries("SideAndIntermediateRelease");
	
EndProcedure

&AtClient
Procedure ByProductsFillInTheCostDivision(Command)
	
	FillInCostDivision("SideAndIntermediateRelease");
	
EndProcedure

#EndRegion

#Region CommandHandlersMaterialsAndWorks

&AtClient
Procedure AddMaterialsAndWorksWithSeparateRemnants(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Command.AddMaterialsAndWorksWithSeparateRemnants");
	// End StandardSubsystems.PerformanceMeasurement
	
	MaterialsAndWorksShouldBeSupplementedWithSeparateBalancesOnServer(CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksPickUpProducts(Command)
	
	OpensGoodsSelection("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksImportDataFromPDT(Command)
	
	GetDataFromTSD("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure RoundUpTheMaterialsAndWorksToTheWholePackage(Command)
	
	RoundToTheWholePackage("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSearchByBarcodeExecute(Command)
	
	SearchByBarcodeExecute("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksGetWeight(Command)
	
	GetWeight("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksInsertLines(Command)
	
	GetLinesFromClipboard("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksCopyLines(Command)
	
	CopyTSLines("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSplitLine(Command)
	
	BreakTSString("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksShouldBeSupplementedAccordingToTheSpecification(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Command.MaterialsAndWorksShouldBeSupplementedAccordingToTheSpecification");
	// End StandardSubsystems.PerformanceMeasurement
	
	AddAccordingToSpecificationOnServer("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksFillInTheCostGroup(Command)
	
	TableCostGroupStartOfSelection("MaterialsAndWorks", True);
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksSpecifyTheSeries(Command)
	
	OpenSelectionOfSeries("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksFillOutTheCalculationArticle(Command)
	
	FillInTheCostingItem("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksFillTheWarehouse(Command)
	
	FillInTheWarehouse("MaterialsAndWorks", "Warehouse");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksFillInTheCostDivision(Command)
	
	FillInCostDivision("MaterialsAndWorks");
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksShowAnalogues(Command)
	
	ShowAnalogues = Not ShowAnalogues;
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
	ConfiguringDependentFormElements(ThisObject, "ShowAnalogues");
	
	 Return; // in UT and KA the handler is empty
	
EndProcedure

&AtClient
Procedure MaterialsAndWorksToFindAnalogues(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Command.MaterialsAndWorksToFindAnalogues");
	
	OpenSelectionOfAnalogues();
	
	Return; // in UT and KA the handler is empty

EndProcedure

#EndRegion

#Region CommandHandlersLabor

&AtClient
Procedure LaborCostsInsertRows(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsCopyLines(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsSplitLine(Command)
	
	BreakTSString("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsAddByBOM(Command)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.BackflushProduction.Form.DocumentForm.Command.LaborCostsAddByBOM");
	// End StandardSubsystems.PerformanceMeasurement
	
	AddAccordingToSpecificationOnServer("LaborCosts");
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCostGroup(Command)
	
	TableCostGroupStartOfSelection("LaborCosts", True);
	
EndProcedure

&AtClient
Procedure LaborCostsFillOutTheCalculationArticle(Command)
	
	FillInTheCostingItem("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsForPerformers(Command)
	
	SelectedRows = Items.LaborCosts.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Bạn phải chọn các dòng để điền vào người thực hiện.';
							|ru = 'Необходимо выбрать строки для заполнения исполнителей.';
							|en = 'Select lines to fill in assignees.'; fa = 'Select lines to fill in assignees.';
							|it = 'È necessario scegliere le righe per la compilazione degli esecutori.';
							|pl = 'Należy wybrać wiersze, aby wprowadzić wykonawców';
							|tr = 'Atananların doldurulması için satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FirstRow = Object.LaborCosts.FindByID(SelectedRows[0]);
	
	CallbackDescription = New CallbackDescription("FillInPerformersCompletion", ThisObject);
	
	ProductionClient.OpenArtistSelectionForm(
		Object.Organization,
		FirstRow.Department,
		FirstRow.Performer,
		Object.Date,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure LaborCostsFillInTheCostDivision(Command)
	
	FillInCostDivision("LaborCosts");
	
EndProcedure

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure HyperlinkLabelProductsClick(Item)
	
	ProductsCollapsed = Not ProductsCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.ManufacturedProducts, 
		Items.HyperlinkLabelProducts, 
		ProductsCollapsed);
	
EndProcedure

&AtClient
Procedure HyperLinkLabelSideProductsClick(Item)
	
	SideProductsAreCollapsed = Not SideProductsAreCollapsed;
	
	SetPropertiesOfCollapsibleGroup(
		Items.SideAndIntermediateRelease, 
		Items.HyperLinkLabelSideProducts, 
		SideProductsAreCollapsed);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

&AtClient
Procedure DisplayInternalProcessing(Command)
	DisplayInternalProcessingOfCurrentDocument = Not DisplayInternalProcessingOfCurrentDocument;
	
	If Not ValueIsFilled(Object.Ref) Then
		DisplayInternalProcessing = DisplayInternalProcessingOfCurrentDocument;
	EndIf;
	
	Items.DisplayInternalProcessing.Check = DisplayInternalProcessingOfCurrentDocument;
	
	DisplayInternalProcessingOnServer();
	Return;
	
EndProcedure

&AtClient
Procedure PickUpGoodsByOrders(Command)
	
	OpenProductSelectionByOrders();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	GroupCostsBeforeChange	= Object.GroupCosts;
	DepartmentBeforeChange		= Object.Department;
	CompanyBeforeChange			= Object.Organization;
	CompanyGiverBeforeChange	= Object.MaterialProviderCompany;
	UseWriteOffForExpenses	=
		GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities")
		Or GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	UseInternalSubcontracting =	GetFunctionalOption("UseInternalSubcontracting");
	
	If UseInternalSubcontracting
		And ValueIsFilled(Object.Organization) Then
		TextOwnerProcessor = StrTemplate(NStr("vi = 'Bên nhận gia công: %1';
												|ru = 'Переработчик: %1';
												|en = 'Subcontractor: %1'; fa = 'Subcontractor: %1';
												|it = 'Переработчик: %1';
												|pl = 'Subcontractor: %1';
												|tr = 'Fason üretici: %1'"), Object.Organization);
	EndIf;
	
	// Hide internal recycling
	If UseInternalSubcontracting Then
		
		DisplayGiversInCostGroup =
			Object.ManufacturedProducts.FindRows(New Structure("InternalSubcontracting", True)).Count() > 0;
		
		DisplayInternalProcessingOfCurrentDocument = DisplayGiversInCostGroup;
		
		FillInDetailsOfOrganization();
		
	EndIf;
	
	Items.DisplayInternalProcessing.Check = DisplayInternalProcessingOfCurrentDocument;
	
	RightToReadSubstitutes = GetFunctionalOption("UseAlternativeMaterials")
						  And AccessRight("Read", Metadata.InformationRegisters.AlternativeMaterials);
	
	Items.MaterialsAndWorksOfAnalogGroup.Visible = RightToReadSubstitutes;
	
	DocumentCurrency = Object.Currency;
	
	// Working with series
	FillInParametersForSpecifyingSeries();
	SetVisibilityOfSeriesElements();
	
	CostAllocationParameters = New FixedStructure(Documents.BackflushProduction.CostAllocationParameters(Object));
	
	FillInServiceDetailsOfForm();
	UpdateListOfCostGroups();
	ConfigureCostGroupingElements(True);
	ConfiguringDependentFormElements(ThisObject);
	
	SetProductGroupHeaders(ThisObject);
	SetArticleSelectionParameters();
	
	LinesOfBusinessServer.OnReadCreateAtServer(ThisObject);
	
	UpdateIssueForActivities(False);
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(Object, Documents.BackflushProduction);
	ProductDataManagement.SetSpecificationSelectionParameters(Items.ManufacturedProductsBillOfMaterials, BOMSelectionParameters);
	
EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Appearance

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	#Region DirectionOfProductionIssue
	
	EstablishConditionalAppearanceDirectionOfRelease("ManufacturedProducts");
	EstablishConditionalAppearanceDirectionOfRelease("SideAndIntermediateRelease");
	
	#EndRegion

	#Region ExpensesBusinessUnit
	
	EstablishConditionalAppearanceForExpenses_("ManufacturedProducts", "Department");
	EstablishConditionalAppearanceForExpenses_("SideAndIntermediateRelease", "ReceivingBusinessUnit");
	
	#EndRegion

	#Region Warehouse
	
	SetConditionalAppearanceRecipient("ManufacturedProducts");
	SetConditionalAppearanceRecipient("SideAndIntermediateRelease");
	
	// explanatory inscription for the warehouse when consuming works
	ProductTypeWork = New ValueList;
	ProductTypeWork.LoadValues(ProductsClientServer.JobSelection(False));
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.MaterialsAndWorksWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "Object.MaterialsAndWorks.ItemsType";
	ConditionalDesignParameters.TypeOfComparisonOfItemTypes = DataCompositionComparisonType.InList;
	ConditionalDesignParameters.ItemsTypes = ProductTypeWork;
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);
	
	#EndRegion

	#Region Department
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndWorks.ShopFloorStockroom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion

	#Region UnitsOfMeasurement

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "ManufacturedProductsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.ManufacturedProducts.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SideAndIntermediateReleaseProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.SideAndIntermediateRelease.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndWorksProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);
		
	#EndRegion

	#Region Characteristics

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
		"ManufacturedProductsCharacteristic",
		"Object.ManufacturedProducts.ItemVariantsAreUsed");
		
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
		"SideAndIntermediateReleaseCharacteristic",
		"Object.SideAndIntermediateRelease.ItemVariantsAreUsed");
		
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
		"MaterialsAndWorksCharacteristic",
		"Object.MaterialsAndWorks.ItemVariantsAreUsed");
		
	#EndRegion

	#Region SetOfSeries
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm,
																		False,
																		"ManufacturedProductsBatchesIndicationStatus",
																		"Object.ManufacturedProducts.BatchesIndicationStatus");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm,
																	False,
																	"ManufacturedProductsSeries",
																	"Object.ManufacturedProducts.BatchesIndicationStatus",
																	"Object.ManufacturedProducts.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm,
																		False,
																		"SideAndIntermediateReleaseBatchesIndicationStatus",
																		"Object.SideAndIntermediateRelease.BatchesIndicationStatus");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm,
																	False,
																	"SideAndIntermediateReleaseSeries",
																	"Object.SideAndIntermediateRelease.BatchesIndicationStatus",
																	"Object.SideAndIntermediateRelease.ItemsType");
	
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisForm,
																		True,
																		"MaterialsAndWorksBatchesIndicationStatus",
																		"Object.MaterialsAndWorks.BatchesIndicationStatus");
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm,
																	"SeriesAlwaysWHGoods",
																	"MaterialsAndWorksSeries",
																	"Object.MaterialsAndWorks.BatchesIndicationStatus",
																	"Object.MaterialsAndWorks.ItemsType");
	
	#EndRegion

	#Region Assignments
	
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																		"ManufacturedProductsPurpose",
																		"Object.ManufacturedProducts.ItemsType",
																		False);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																		"SideAndIntermediateReleasePurpose",
																		"Object.SideAndIntermediateRelease.ItemsType",
																		False);
	ProductsServer.SetConditionalAppearanceOfProductAssignment(ThisForm,
																		"MaterialsAndWorksPurpose",
																		"Object.MaterialsAndWorks.ItemsType",
																		False);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsPurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleasePurpose.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	
	#EndRegion
	
	#Region GroupCosts
	
	// Setting the visibility of the Expense group column of the product table
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsExpenseGroup.Name);
	
	OrGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Patch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CorrectionSavesProductionLots");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Setting the visibility of the column of the group of expenses of the cost parts
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsExpenseGroup.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseExpenseGroup.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndWorksExpenseGroup.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsExpenseGroup.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByDocument);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified);
	ItemFilter.RightValue = ValueList;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// The Bill of Materials is required only for grouping "By Bill of Materials"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsBillOfMaterials.Name);
	
	OrGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ValueList = New ValueList;
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments);
	ItemFilter.RightValue = ValueList;
	
	AndGroup = OrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Patch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CorrectionSavesProductionLots");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Assignment is required only for groupings by assignment
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsPurpose.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	
	ValueList = New ValueList;
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments);
	
	ItemFilter.RightValue = ValueList;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region ManufacturedProductsCostShare
	
	// Setting the percentage registration
	ProductionServer.SetConditionalAppearanceOfShareCostPercentageField(ThisForm, "Object", "ManufacturedProducts");
	
	// Setting the visibility of the Cost Share column by cost grouping
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostShare.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsCostSharePercentage.Name);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsThereAreErrorsOfFillingInCostShare.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProducts);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches);
	ValueList.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches);
	ItemFilter.RightValue = ValueList;
	
	OrGroup = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Patch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = OrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CorrectionSavesProductionLots");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// share of the cost (mark blank)
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsCostShare.Name); 
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.CostShareRequired_");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ManufacturedProducts.CostShare");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	#EndRegion

	#Region LaborCostsTeam

	// Setting the mark of the blank field Brigade
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsPerformer.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReferenceOrderForLaborCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion

	#Region TargetCost
	
	// Visibility of planned cost fields.
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsPrice.Name);
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ManufacturedProductsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseTargetCost");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);

	#EndRegion

	#Region ManufacturedProductsInternalSubcontracting
	
	// Internal processing is not displayed if specified in the header.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsInternalSubcontracting.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsMaterialProviderCompany.Name);
	
	DimensionsByDocument = New ValueList;
	DimensionsByDocument.Add(Enums.GroupingsOfCostsInBackflushProduction.ByDocument);
	DimensionsByDocument.Add(Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = DimensionsByDocument;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// All Attributes of internal processing are not displayed on Command.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsInternalSubcontracting.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsMaterialProviderCompany.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseProductOwner.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DisplayInternalProcessingOfCurrentDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// "Giver organization" is a hint.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsMaterialProviderCompany.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.MaterialProviderCompany");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text",      NStr("vi = '<doanh nghiệp-người đặt gia công>';
														|ru = '<организации-давальца>';
														|en = '<material provider company>'; fa = '<شرکت تأمین‌کننده مواد>';
														|it = '<организации-давальца>';
														|pl = '<material provider company>';
														|tr = '<tedarikçi iş yerleri>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// "Internal processing" - not available in the fix.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsInternalSubcontracting.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsMaterialProviderCompany.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Patch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CorrectionSavesProductionLots");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	
	// "Giver organization" is not available if internal processing is disabled.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ManufacturedProductsMaterialProviderCompany.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	#EndRegion
	
	#Region SideAndIntermediateReleaseProductOwner
	
	DataPaths = New Structure;
	DataPaths.Insert("InternalSubcontracting", "UseInternalSubcontracting");
	DataPaths.Insert("MaterialProviderCompany",    "Object.SideAndIntermediateRelease.MaterialProviderCompany");
	DataPaths.Insert("TextOwnerGiver",  "Object.SideAndIntermediateRelease.TextOwnerGiver");
	
	ItemNamesByProducts = New Structure;
	ItemNamesByProducts.Insert("ProductOwner", Items.SideAndIntermediateReleaseProductOwner.Name);
	
	InternalSubcontractingServer.SetConditionalAppearanceOfProductOwnerField(
		ThisObject,
		"Object",
		"SideAndIntermediateRelease",
		ItemNamesByProducts,
		DataPaths);
	
	// Setting the visibility of the "Product Owner" column from the expense grouping
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseProductOwner.Name);
	
	DimensionsByDocument = New ValueList;
	DimensionsByDocument.Add(Enums.GroupingsOfCostsInBackflushProduction.ByDocument);
	DimensionsByDocument.Add(Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.GroupCosts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = DimensionsByDocument;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Setting the availability of the "Product Owner" column of a specific Expense group
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SideAndIntermediateReleaseProductOwner.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly",        True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<đối với nhóm chi phí-gia công nội bộ>';
																	|ru = '<для групп затрат внутренней переработки>';
																	|en = '<for cost groups of internal subcontracting>'; fa = '<for cost groups of internal subcontracting>';
																	|it = '<для групп затрат внутренней переработки>';
																	|pl = '<for cost groups of internal subcontracting>';
																	|tr = '<dahili geri dönüşüm maliyet grupları için>'"));
	Item.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	
	#EndRegion
	

EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceDirectionOfRelease(TSName)
	
	If TSName = "ManufacturedProducts" Then
		NameOfReleaseDirectionField      = "ManufacturedProductsDirectionOfProductionIssue";
		PathToFieldReleaseDirection    = "Object.ManufacturedProducts.DirectionOfProductionIssue";
	Else
		NameOfReleaseDirectionField      = "SideAndIntermediateReleaseDirectionOfProductionIssue";
		PathToFieldReleaseDirection    = "Object.SideAndIntermediateRelease.DirectionOfProductionIssue";
	EndIf;
	
	ReleaseDirectionField = Items[NameOfReleaseDirectionField]; // FormField
	
	
	// On a warehouse
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ReleaseDirectionField.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldReleaseDirection);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điều chuyển hàng hóa';
													|ru = 'На склад';
													|en = 'To warehouse'; fa = 'To warehouse';
													|it = 'Al magazzino';
													|pl = 'Na magazyn';
													|tr = 'Ambara'"));
	
	// To the division
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ReleaseDirectionField.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldReleaseDirection);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Sang bộ phận';
													|ru = 'В подразделение';
													|en = 'To business unit'; fa = 'To business unit';
													|it = 'Al reparto';
													|pl = 'Do działu';
													|tr = 'Departmana'"));

	// To the article
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ReleaseDirectionField.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldReleaseDirection);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списать на расходы';
													|en = 'Expense as'; fa = 'هزینه به عنوان';
													|it = 'Stornare sulle spese';
													|pl = 'Spisać w koszty';
													|tr = 'Giderlere yaz'"));
	
EndProcedure

&AtServer
Procedure EstablishConditionalAppearanceForExpenses_(TSName, FieldName)

	If TSName = "ManufacturedProducts" Then
		FieldNameDivision        = "ManufacturedProductsDepartment";
		PathToFieldReleaseDirection = "Object.ManufacturedProducts.DirectionOfProductionIssue";
		PathToFieldDivision      = "Object.ManufacturedProducts.Department";
	Else
		FieldNameDivision        = "SideAndIntermediateReleaseReceivingBusinessUnit";
		PathToFieldReleaseDirection = "Object.SideAndIntermediateRelease.DirectionOfProductionIssue";
		PathToFieldDivision      = "Object.SideAndIntermediateRelease.ReceivingBusinessUnit";
	EndIf;
	
	FormField = Items[FieldNameDivision]; // FormField
	
	// Visibility of the receiving unit of output items
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldReleaseDirection);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// The receiving unit of the output items coincides with the issuing one
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldReleaseDirection);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToFieldDivision);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField("Object.Department"));
	
EndProcedure

&AtServer
Procedure SetConditionalAppearanceRecipient(TSName)
	
	// explanatory inscription for the warehouse, if the full name "Several warehouses" is not used
	Item = ConditionalAppearance.Items.Add();
	
	RecipientField = Items[TSName + "Recipient"]; // FormField
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(RecipientField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseSeveralWarehouses");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Products.EmptyRef();
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	
	ValueList = New ValueList;
	ValueList.Add(Enums.ItemsTypes.OwnGoods);
	ValueList.Add(Enums.ItemsTypes.ReusablePackage);
	
	ItemFilter.RightValue = ValueList;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object." + TSName + ".DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<dành cho công việc>';
													|ru = '<для работ>';
													|en = '<for works>'; fa = '<for works>';
													|it = '<per i lavori>';
													|pl = '<dla robót>';
													|tr = '<iş için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetProductGroupHeaders(Form, AttributesList = "")
	
	AttributesStructure1 = New Structure(AttributesList);
	Initialize = IsBlankString(AttributesList);
	
	FinishedProductsQuantity = Form.Object.ManufacturedProducts.Count();
	SideProductsQuantity = Form.Object.SideAndIntermediateRelease.Count();
	
	GroupingWithoutCosts =
		PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified");
	
	If Form.Object.GroupCosts = GroupingWithoutCosts Then
		Form.Items.GroupLabelProducts.Visible = False;
		Form.Items.GroupLabelSideProducts.Visible = False;
		Form.NumberOfProducts = FinishedProductsQuantity;
		Return;
	Else
		Form.Items.GroupLabelProducts.Visible = True;
		Form.Items.GroupLabelSideProducts.Visible = True;
		Form.NumberOfProducts = FinishedProductsQuantity + SideProductsQuantity;
	EndIf;
	
	If AttributesStructure1.Property("ManufacturedProducts")
			Or Initialize Then
		LabelProducts = NStr("vi = 'Sản phẩm có giá trị ước tính %1';
							|ru = 'Продукция по рассчитываемой стоимости%1';
							|en = 'Products at the calculated cost%1'; fa = 'Products at the calculated cost%1';
							|it = 'Prodotto in base al valore calcolato %1';
							|pl = 'Wiersze pozycji według szacowanej ceny%1';
							|tr = 'Hesaplanan maliyete göre imal edilen ürünler%1'");
		LabelProducts =
			StringFunctionsClientServer.SubstituteParametersToString(
				LabelProducts,
				?(FinishedProductsQuantity <> 0, " (" + FinishedProductsQuantity + ")", ""));
		
		Form.LabelProducts = LabelProducts;
	EndIf;
			
	If AttributesStructure1.Property("SideAndIntermediateRelease")
			Or Initialize Then
		LabelSideProducts = NStr("vi = 'Sản phẩm phụ và xuất xưởng trung gian với giá thành cố định %1';
								|ru = 'Побочный и промежуточный выпуск по фиксированной стоимости%1';
								|en = 'Side and intermediate release at fixed cost%1'; fa = 'Side and intermediate release at fixed cost%1';
								|it = 'Produzione collaterale e intermedia al costo fisso%1';
								|pl = 'Produkcja uboczna i pośrednia według stałej ceny%1';
								|tr = 'Sabit maliyetle yan ve ara ürün çıkışı%1'");
		LabelSideProducts =
			StringFunctionsClientServer.SubstituteParametersToString(
				LabelSideProducts, ?(SideProductsQuantity <> 0, " (" + SideProductsQuantity + ")", ""));
		
		Form.LabelSideProducts = LabelSideProducts;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureCostGroupingElements(Initialize)
	
	// Setting up editing fields that affect production Lot references
	
	OnlyViewingPartyFields =
		Object.Patch
		And Object.CorrectionSavesProductionLots;
	
	Items.GroupCosts.ReadOnly       = OnlyViewingPartyFields;
	Items.Organization.ReadOnly             = OnlyViewingPartyFields;
	Items.LineOfBusiness.ReadOnly = OnlyViewingPartyFields;
	Items.ProductionIssueForActivity.ReadOnly   = OnlyViewingPartyFields;
	Items.InternalSubcontracting.ReadOnly   = OnlyViewingPartyFields;
	// Let's limit the available cost grouping values
	CostGroupingSelectionOptions = New Array;
	
	SpecifyTargets = GetFunctionalOption("UseOrderSupplyWithAssignment");
	If Not SpecifyTargets Then
		
		AvailableValues = New Array;
		
		If ValueIsFilled(Object.GroupCosts) Then
			AvailableValues.Add(Object.GroupCosts);
		EndIf;
		
		AvailableValues.Add(Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified);
		AvailableValues.Add(Enums.GroupingsOfCostsInBackflushProduction.ByDocument);
		AvailableValues.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProducts);
		AvailableValues.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductsWithoutBatches);
		AvailableValues.Add(Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM);
		AvailableValues = CommonClientServer.CollapseArray(AvailableValues);
		
		NewParameter1 = New ChoiceParameter("Filter.Ref", New FixedArray(AvailableValues));
		CostGroupingSelectionOptions.Add(NewParameter1);
		
	EndIf;
	
	Items.GroupCosts.ChoiceParameters = New FixedArray(CostGroupingSelectionOptions);
	
	FieldList = Documents.BackflushProduction.ListOfCostGroupFields(Object.GroupCosts);
	
	CostGroupPresentation = "";
	
	For Each CurField In FieldList Do
		
		If ValueIsFilled(CurField.Presentation) Then
			If Not DisplayGiversInCostGroup
				And CurField.Value = "MaterialProviderCompany" Then
				Continue;
			EndIf;
			CostGroupPresentation = CostGroupPresentation + CurField.Presentation + " / ";
			
		EndIf;
	EndDo;
	
	CostGroupPresentation = " (" + Left(CostGroupPresentation, StrLen(CostGroupPresentation) - 3) + ")";
	
	CostGroupHeader = NStr("vi = 'Nhóm chi phí %1';
							|ru = 'Группа затрат%1';
							|en = 'Cost group%1'; fa = 'Cost group%1';
							|it = 'Gruppo delle spese%1';
							|pl = 'Grupa kosztów%1';
							|tr = 'Maliyet grubu%1'");
	
	If Not FieldList.Count() = 0 Then
		CostGroupHeader =
			StringFunctionsClientServer.SubstituteParametersToString(CostGroupHeader, CostGroupPresentation);
	EndIf;
	
	GroupHintOutputProducts	= NStr("vi = '%1, mà sản phẩm liên quan';
										|ru = '%1, к которой относится изделие';
										|en = '%1 to which the product belongs'; fa = '%1 to which the product belongs';
										|it = '%1 to which the product belongs';
										|pl = '%1 to which the product belongs';
										|tr = 'Nihai ürün dahilindeki %1'");
	GroupHintByProducts	= NStr("vi = '%1 có phế liệu thu hồi';
									|ru = '%1, к которой относится возвратный отход';
									|en = '%1 to which recyclable waste belongs'; fa = '%1 to which recyclable waste belongs';
									|it = '%1, al quale appartiene lo scarto riciclabile';
									|pl = '%1, do której należy odpad zwrotny';
									|tr = 'Geri dönüştürülebilir atık dahilindeki  %1'");
	MaterialsAndWorksGroupHint	= NStr("vi = '%1 có chi phí nguyên vật liệu/nhân công';
										|ru = '%1, к которой относится материал/работа';
										|en = '%1 to which material/work belongs'; fa = '%1 to which material/work belongs';
										|it = '%1, al quale appartiene il materiale/lavoro';
										|pl = '%1, do której należy materiał/praca';
										|tr = 'Malzeme/iş dahilindeki %1'");
	GroupHintLaborCosts		= NStr("vi = '%1 có chi phí nhân công';
										|ru = '%1, к которой относится трудозатрата';
										|en = '%1 to which labor costs belong'; fa = '%1 to which labor costs belong';
										|it = '%1, al quale appartiene il costo di manodopera';
										|pl = '%1, do której należą nakłady pracy';
										|tr = 'İş gücü maliyetleri dahilindeki %1'");
	
	GroupHintByProducts	=
		StringFunctionsClientServer.SubstituteParametersToString(GroupHintByProducts, CostGroupHeader);
	MaterialsAndWorksGroupHint	=
		StringFunctionsClientServer.SubstituteParametersToString(MaterialsAndWorksGroupHint, CostGroupHeader);
	GroupHintLaborCosts		=
		StringFunctionsClientServer.SubstituteParametersToString(GroupHintLaborCosts, CostGroupHeader);
	
	Items.ManufacturedProductsExpenseGroup.Title = CostGroupHeader;
	Items.OutputItemsFillCostGroup.Visible =
		Object.Patch
		And Object.CorrectionSavesProductionLots;
	Items.OutputItemsFillCostGroupExtendedTooltip.Title = GroupHintOutputProducts;
	
	VisibilityOfCommandsFill =
		Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified
		And Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument;
	
	Items.SideAndIntermediateReleaseExpenseGroup.Title = CostGroupHeader;
	Items.ByProductsFillInTheCostGroup.Visible = VisibilityOfCommandsFill;
	Items.ByProductsFillInTheCostGroupExtendedTooltip.Title = GroupHintByProducts;
	
	Items.MaterialsAndWorksExpenseGroup.Title = CostGroupHeader;
	Items.MaterialsAndWorksFillInTheCostGroup.Visible = VisibilityOfCommandsFill;
	Items.MaterialsAndWorksFillInTheCostGroupExtendedTooltip.Title = MaterialsAndWorksGroupHint;
	
	Items.LaborCostsExpenseGroup.Title = CostGroupHeader;
	Items.LaborCostsFillInTheCostGroup.Visible = VisibilityOfCommandsFill;
	Items.LaborCostsFillInTheCostGroupExtendedTooltip.Title = GroupHintLaborCosts;
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		Items.PriceKind.Visible					= UseTargetCost;
		Items.Currency.Visible					= UseTargetCost;
		Items.GroupByProducts_2.Visible	= False;
		Items.GroupMaterialsAndWorks.Visible	= False;
		Items.LaborCostsGroup.Visible		= False;
	Else
		Items.PriceKind.Visible					= True;
		Items.Currency.Visible					= True;
		Items.GroupByProducts_2.Visible	= True;
		Items.GroupMaterialsAndWorks.Visible	= True;
		Items.LaborCostsGroup.Visible		= True;
	EndIf;
	
	If Initialize Then
		
		SideProductsAreCollapsed = True;
		SetPropertiesOfCollapsibleGroup(
			Items.SideAndIntermediateRelease, 
			Items.HyperLinkLabelSideProducts, 
			SideProductsAreCollapsed);
		
	EndIf;
	
	Items.MethodOfAllocatingFinishedProductCosts.Visible =
		Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified
		Or Object.Patch
			And Object.CorrectionSavesProductionLots;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetPropertiesOfCollapsibleGroup(GroupItem1, PictureGroup, GroupCollapsed)

	GroupItem1.Visible = Not GroupCollapsed;
	
	If GroupCollapsed Then
		PictureGroup.Picture = PictureLib.RightArrow;
	Else
		PictureGroup.Picture = PictureLib.DownArrow;
	EndIf; 

EndProcedure

&AtServer
Procedure SetArticleSelectionParameters()
	
	ArticleSelectionParameters = New Array;
	ArticleSelectionParameters.Add(New ChoiceParameter("AddExpenseItems", True));
	ArticleSelectionParameters.Add(New ChoiceParameter("AddItemsOfAssetsLiabilities", True));
	ArticleSelectionParameters.Add(
		New ChoiceParameter("Filter.BusinessOperation", Enums.BusinessTransactions.ProductsRelease));
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	OptionsArray.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostCenters);
	OptionsArray.Add(Enums.CostAllocationOptions.ToInventoryCost);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostOfGoodsSold);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	
	ArticleSelectionParameters.Add(
		New ChoiceParameter("Filter.CostAllocationOption", New FixedArray(OptionsArray)));
	
	Items.ManufacturedProductsRecipient.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	Items.SideAndIntermediateReleaseRecipient.ChoiceParameters = New FixedArray(ArticleSelectionParameters);
	
EndProcedure

&AtClient
Procedure RestrictRecipientType(TSName, CurrentData)

	If TSName = "ManufacturedProducts" Then
		RecipientFieldName = "ManufacturedProductsRecipient";
	Else
		RecipientFieldName = "SideAndIntermediateReleaseRecipient";
	EndIf;

	If CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit") Then
		TypeRestriction = New TypeDescription("CatalogRef.BusinessStructure");
	ElsIf CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		TypeRestriction =
			New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems, ChartOfCharacteristicTypesRef.ExpenseItems");
	Else
		TypeRestriction = New TypeDescription("CatalogRef.Warehouses");
	EndIf; 
	
	Items[RecipientFieldName].TypeRestriction = TypeRestriction;
	CurrentData.Recipient =
		Items[RecipientFieldName].TypeRestriction.AdjustValue(CurrentData.Recipient);

EndProcedure

&AtClientAtServerNoContext
Procedure ConfiguringDependentFormElements(Form, AttributesList = "")
	
	Object   = Form.Object;
	Items = Form.Items;
	
	AttributesList = New Structure(AttributesList);
	Initialize    = Not ValueIsFilled(AttributesList.Count());
	
	If Initialize
		Or AttributesList.Property("Date")
		Or AttributesList.Property("Organization") Then
			
		Items.OutputProductsFillInThePricesAccordingToTheCalculation.Visible = False;
		Items.OutputProductsFillInPricesByPriceType.Visible = Form.UseTargetCost;
		Items.OutputProductsFillInThePricesAccordingToTheCalculation.Visible = Form.UseTargetCost;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("GroupCosts") Then
		
		ItemVisibility = False;
		ItemVisibility =
			Object.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.ByDocument")
			Or Object.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified");
		Items.InternalProcessingGroup.Visible = ItemVisibility;
		
		ItemVisibility = False;
		ItemVisibility =
			Not Object.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.ByDocument")
			And Not Object.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified");
		Items.DisplayInternalProcessing.Visible = ItemVisibility;
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("Organization") Then
		
		ArtistSelectionParameters = New Array;
		
		If ValueIsFilled(Object.Organization) Then
			
			CurrencySelectionParameterAccountingReg = New ChoiceParameter("Filter.LocalAccountingCurrency", Form.LocalAccountingCurrency);
			ArtistSelectionParameters.Add(CurrencySelectionParameterAccountingReg);
			
			CountryOfRegistrationSelectionParameter = New ChoiceParameter("Filter.RegistrationCountry", Form.RegistrationCountry);
			ArtistSelectionParameters.Add(CountryOfRegistrationSelectionParameter);
			
			OrganizationChoiceParameter = New ChoiceParameter("ModeForSelectingRelatedOrganizations", "JustNotInterconnected");
			ArtistSelectionParameters.Add(OrganizationChoiceParameter);
			
			OrganizationChoiceParameter = New ChoiceParameter("Organization", Object.Organization);
			ArtistSelectionParameters.Add(OrganizationChoiceParameter);
			
		EndIf;
		
		Items.MaterialProviderCompany.ChoiceParameters = New FixedArray(ArtistSelectionParameters);
		Items.ManufacturedProductsMaterialProviderCompany.ChoiceParameters = New FixedArray(ArtistSelectionParameters);
		
	EndIf;
	
	If Initialize
		Or AttributesList.Property("InternalSubcontracting") Then
		Items.MaterialProviderCompany.ReadOnly =
			Not Object.InternalSubcontracting
			Or Object.Patch
				And Object.CorrectionSavesProductionLots;
	EndIf;
	
	If Initialize
		Or AttributesList.Property("InternalSubcontracting")
		Or AttributesList.Property("MaterialProviderCompany") Then
		Items.MaterialProviderCompany.MarkIncomplete =
			Object.InternalSubcontracting
			And Not ValueIsFilled(Object.MaterialProviderCompany);
	EndIf;
	
	If Initialize
		Or AttributesList.Property("ShowAnalogues") Then
		
		Items.MaterialsAndWorksShowAnalogues.Check = Form.ShowAnalogues;
		
		Items.MaterialsAndWorksThereAreSubstituteMaterials.Visible =
			Form.RightToReadSubstitutes
			And Form.ShowAnalogues
			And Object.GroupCosts <>
				PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified");
		
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure FillInSelectionListOfProductOwners(Form)
	
	Object   = Form.Object;
	Items = Form.Items;
	
	ChoiceList = Items.SideAndIntermediateReleaseProductOwner.ChoiceList;
	ChoiceList.Clear();
	
	CurrentData = Items.SideAndIntermediateRelease.CurrentData;
	
	If ValueIsFilled(CurrentData.TextOwnerGiver) Then
		ChoiceList.Add(CurrentData.MaterialProviderCompany, CurrentData.TextOwnerGiver);
	EndIf;
	
	If ValueIsFilled(Form.TextOwnerProcessor) Then
		ChoiceList.Add(Object.Organization, Form.TextOwnerProcessor);
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckOwnerOfProducts(CostGroupNumber = Undefined)
	
	If ValueIsFilled(CostGroupNumber) Then
		TheStructureOfTheSearch = New Structure("CostGroupNumber", CostGroupNumber);
		FoundRows = Object.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch);
	Else
		FoundRows = Object.SideAndIntermediateRelease;
	EndIf;
	
	For Each CurrentData In FoundRows Do
		
		If CurrentData.InternalSubcontracting
			And ValueIsFilled(CurrentData.ProductOwner)
			And CurrentData.ProductOwner = CompanyBeforeChange Then
			CurrentData.ProductOwner = Object.Organization;
		Else
			CurrentData.ProductOwner = Undefined;
		EndIf;
		
	EndDo;
	
EndProcedure
#EndRegion

#Region SetOfSeries

&AtServer
Procedure FillInParametersForSpecifyingSeries()
	
	SeriesSpecificationParameters =
		New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.BackflushProduction));
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(TSName, CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters[TSName],
														CurDataId,
														ThisForm);
	
EndFunction

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.ManufacturedProductsSeries.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.ManufacturedProductsBatchesIndicationStatus.Visible =
		SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	Items.OutputProductsSpecifyTheSeries.Visible = SeriesSpecificationParameters.ManufacturedProducts.UseItemsBatch;
	
	Items.SideAndIntermediateReleaseSeries.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.SideAndIntermediateReleaseBatchesIndicationStatus.Visible =
		SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	Items.ByProductsSpecifyTheSeries.Visible = SeriesSpecificationParameters.SideAndIntermediateRelease.UseItemsBatch;
	
	Items.MaterialsAndWorksSeries.Visible = SeriesSpecificationParameters.MaterialsAndWorks.UseItemsBatch;
	Items.MaterialsAndWorksBatchesIndicationStatus.Visible =
		SeriesSpecificationParameters.MaterialsAndWorks.UseItemsBatch;
	Items.MaterialsAndWorksSpecifyTheSeries.Visible =
		SeriesSpecificationParameters.MaterialsAndWorks.UseItemsBatch;
	
EndProcedure

&AtClient
Procedure UpdateCachedValuesToAccountForSeries(TSName, Item, CachedValues, Copy)
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item, CachedValues, SeriesSpecificationParameters[TSName], Copy);
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(TSName, Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
							ThisObject,
							SeriesSpecificationParameters[TSName],
							Text,
							CurrentData);
	
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items[TSName].CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(TSName, CurDataId);
		AdditionalParameters = New Structure("SeriesSpecificationParameters,ParametersOfSeriesIndicationForm, TSName", 
											SeriesSpecificationParameters[TSName], ParametersOfSeriesIndicationForm, TSName);
		CallbackDescription = New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,
						ParametersOfSeriesIndicationForm,
						ThisObject,,,,
						CallbackDescription);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		ProcessSeriesIndication_Server(
			AdditionalParameters.TSName,
			AdditionalParameters.SeriesSpecificationParameters,
			AdditionalParameters.ParametersOfSeriesIndicationForm);
		
		CurrentData = Items[AdditionalParameters.TSName].CurrentData;
		
		StructureOfActions = New Structure;
		If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentData.Products, "Series", Object.Date) Then
			
			If AdditionalParameters.TSName = "ManufacturedProducts" Then
				StructureOfActions.Insert("CheckFillInCostShare", CostAllocationParameters);
			EndIf;
			
			If (AdditionalParameters.TSName = "ManufacturedProducts" And UseTargetCost)
				Or AdditionalParameters.TSName = "SideAndIntermediateRelease" Then
				
				ParametersStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
				ParametersStructure.Insert("PriceKind", Object.PriceKind);
				StructureOfActions.Insert("FillInSalePrice", ParametersStructure);
				StructureOfActions.Insert("RecalculateAmount", "Count");
				
			EndIf;
			
		EndIf;
		
		If Not StructureOfActions.Count() = 0 Then
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(Val TSName, Val SeriesSpecificationParameters, Val ParametersOfSeriesIndicationForm)
	
	If SeriesSpecificationParameters.NameTSGoods = "ManufacturedProducts"
		Or SeriesSpecificationParameters.NameTSGoods = "SideAndIntermediateRelease" Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
		AddActionsToStructureWhenChangingPackagesNumber(
			SeriesSpecificationParameters.NameTSGoods,
			ThisObject,
			StructureOfActions);
	Else
		StructureOfActions = Undefined;
	EndIf;
	
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters,
		ParametersOfSeriesIndicationForm,
		StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer(TSName,
											RowsOfProductsToProcess = Undefined,
											SeriesRowsToProcess = Undefined)
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,
													SeriesSpecificationParameters[TSName],
													RowsOfProductsToProcess,
													SeriesRowsToProcess);
	
EndProcedure

&AtServer
Procedure DistributeBatchesOfProductsByCostGroups(TSName)
	
	If TSName = "ManufacturedProducts" Then
		TSSeriesName = "BatchFinishedProducts";
	Else
		TSSeriesName = "BatchSideAndIntermediateRelease";
	EndIf;
	
	If Not SeriesSpecificationParameters[TSName].UseItemsBatch
		Or Object[TSSeriesName].Count() = 0 Then
		Return;
	EndIf;
	
	// Let's collapse the table of products by fields of connection with the table of series
	Products_Fields = Common.CopyRecursive(SeriesSpecificationParameters[TSName].LinkFields);
	Products_Fields.Add("Products");
	Products_Fields.Add("Characteristic");
	
	ProductTable_ = Object[TSName].Unload(); // ValueTable
	ProductTable_.GroupBy(StrConcat(Products_Fields, ","), "Count");
	
	// Let's collapse the series table by communication fields, but without the cost group numbers - they will be refilled.
	BatchesFields = Common.CopyRecursive(Products_Fields);
	IndexOfCostGroupNumber = BatchesFields.Find("CostGroupNumber");
	If Not IndexOfCostGroupNumber = Undefined Then
		BatchesFields.Delete(IndexOfCostGroupNumber);
	EndIf;
	SearchKey = StrConcat(BatchesFields, ",");
	
	BatchesFields.Add("Series");
	
	TableOfSeries      = Object[TSSeriesName].Unload(); // ValueTable
	BatchTableIsNew = TableOfSeries.CopyColumns();
	
	TableOfSeries.GroupBy(StrConcat(BatchesFields, ","), "Count");
	TableOfSeries.Indexes.Add(SearchKey);
	
	For Each CurrentFinishedProduct In ProductTable_ Do
		
		ManufacturedProductQuantity = CurrentFinishedProduct.Count;
		
		Filter = New Structure(SearchKey);
		FillPropertyValues(Filter, CurrentFinishedProduct);
		
		For Each CurSeries_ In TableOfSeries.FindRows(Filter) Do
			
			If CurSeries_.Count = 0 Then
				Continue;
			EndIf;
			
			NumberOfSeries_ = Min(ManufacturedProductQuantity, CurSeries_.Count);
			
			NewRowSeries = BatchTableIsNew.Add();
			FillPropertyValues(NewRowSeries, CurSeries_);
			
			NewRowSeries.CostGroupNumber = CurrentFinishedProduct.CostGroupNumber;
			NewRowSeries.Count        = NumberOfSeries_;
			
			ManufacturedProductQuantity       = ManufacturedProductQuantity - NumberOfSeries_;
			CurSeries_.Count = CurSeries_.Count - NumberOfSeries_;
			
			If ManufacturedProductQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Object[TSSeriesName].Load(BatchTableIsNew);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
				Val SeriesSpecificationParameters,
				IDCurrentRow,
				CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtClient
Procedure AfterDeletingTSLines(TSName, Item)
	
	SeriesStatusesNeedToBeUpdated = ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item, CachedValues, SeriesSpecificationParameters[TSName], True);
	
	If TSName = "ManufacturedProducts"
		Or SeriesStatusesNeedToBeUpdated Then
		
		AfterDeletingTSLinesOnServer(TSName, SeriesStatusesNeedToBeUpdated, CachedValues);
		
		If SeriesStatusesNeedToBeUpdated Then
			ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item, CachedValues, SeriesSpecificationParameters[TSName]);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterDeletingTSLinesOnServer(TSName, SeriesStatusesNeedToBeUpdated, CachedValues)
	
	If SeriesStatusesNeedToBeUpdated Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
			SeriesSpecificationParameters[TSName],
			Undefined,
			CachedValues);
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_ManufacturedProducts()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.ManufacturedProducts.FindByID(CurDataId);
	
	OpenSelectionOfSeries("ManufacturedProducts", , CurrentData);
	
EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_SideAndIntermediateRelease()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.SideAndIntermediateRelease.FindByID(CurDataId);
	
	OpenSelectionOfSeries("SideAndIntermediateRelease", , CurrentData);
	
EndProcedure

&AtClient
Procedure Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorks()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.MaterialsAndWorks.FindByID(CurDataId);
	
	OpenSelectionOfSeries("MaterialsAndWorks", , CurrentData);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(TSName)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(TSName)
	
	NumberOfProductsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboardOnServer(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	If TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Or TSName = "MaterialsAndWorks" Then
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
	Else
		FilterParameters = Undefined;
	EndIf;
	
	Columns = "Products,Characteristic,WorkKind,Package,NumberOfPackages,Count,Price,Warehouse,Department,
		|BillOfMaterials,DirectionOfProductionIssue,ProductCostElement,Performer";
	
	TableOfRows = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfRows) Then
		Return;
	EndIf;
	
	ObjectTable = Object[TSName]; // FormDataCollection
	RowsArray = New Array;
	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfRows Do
		
		CurrentRow = ObjectTable.Add();
		FillPropertyValues(CurrentRow, RowOfProduct);
		If TSName = "ManufacturedProducts" Then
			CurrentRow.InternalSubcontracting = Object.InternalSubcontracting;
			CurrentRow.MaterialProviderCompany    = Object.MaterialProviderCompany;
		EndIf;
		RowsArray.Add(CurrentRow.GetID());
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	StructureOfActions = New Structure;
	If TSName = "ManufacturedProducts" 
		Or TSName = "SideAndIntermediateRelease" 
		Or TSName = "MaterialsAndWorks" Then
		
		AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True, TSName = "MaterialsAndWorks");
		AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
		
	EndIf;
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	EndIf;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable,
		CachedValues);
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		
		If TSName = "ManufacturedProducts" Then
			KTCHPath = "Object.ManufacturedProducts";
		Else
			KTCHPath = "Object.SideAndIntermediateRelease";
		EndIf;
		
		For Each CurrentRow In RowsToProcess Do
			
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, KTCHPath);
			
			If TSName = "ManufacturedProducts" Then
				AddChangeCostGroup(CurrentRow);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	CommandsAvailability = ProcessingOfTabularForms.ThereAreLinesInClipboard();
	
	Items.ManufacturedProductsInsertRows.Enabled = CommandsAvailability;
	Items.OutputItemsContextMenuInsertLines.Enabled = CommandsAvailability;
	
	Items.ByProductsInsertRows.Enabled = CommandsAvailability;
	Items.ByProductsContextMenuInsertLines.Enabled = CommandsAvailability;
	
	Items.MaterialsAndWorksInsertLines.Enabled = CommandsAvailability;
	Items.MaterialsAndWorksContextMenuInsertLines.Enabled = CommandsAvailability;
	
	Items.LaborCostsInsertRows.Enabled = CommandsAvailability;
	Items.LaborCostsContextMenuInsertLines.Enabled = CommandsAvailability;
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("ManufacturedProductsInsertRows");
	ItemArray.Add("OutputItemsContextMenuInsertLines");
	ItemArray.Add("ByProductsInsertRows");
	ItemArray.Add("ByProductsContextMenuInsertLines");
	ItemArray.Add("MaterialsAndWorksInsertLines");
	ItemArray.Add("MaterialsAndWorksContextMenuInsertLines");
	ItemArray.Add("LaborCostsInsertRows");
	ItemArray.Add("LaborCostsContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

#Region ActionsWhenChangingTableRows

// This procedure should be used if the rows were added programmatically (not interactively), for example,
// when pasting from a buffer, or when filling in according to the specification.
// The procedure performs actions that depend on the data in the rows.
//
&AtServer
Procedure AfterChangingTSStringsProgrammaticallyOnServer(TSName,
												ArrayOfRowIDs_ = Undefined,
												StructureOfPreviouslyPerformedActions = Undefined)

	RowsArray = Undefined;
	ArrayOfDimensions = New Array;
	RowsCollection = Object[TSName];
	If ArrayOfRowIDs_ <> Undefined Then
		RowsArray = New Array;
		For Each RowID In ArrayOfRowIDs_ Do
			RowData = Object[TSName].FindByID(RowID);
			RowsArray.Add(RowData);
			If TSName = "ManufacturedProducts" Then
				ArrayOfDimensions.Add(RowData.CostGroupNumber);
			EndIf;
		EndDo;
		RowsCollection = RowsArray;
	EndIf;
	
	If StructureOfPreviouslyPerformedActions = Undefined Then
		StructureOfPreviouslyPerformedActions = New Structure;
	EndIf;
	
	If (TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease"
			Or TSName = "MaterialsAndWorks")
		And Not StructureOfPreviouslyPerformedActions.Property("CheckSeriesCalculateStatus") Then
		FillInStatusesForSpecifyingSeriesServer(TSName, RowsArray, RowsArray);
	EndIf; 
	
	If TSName = "ManufacturedProducts"
		And (Not Object.Patch
			Or Not Object.CorrectionSavesProductionLots) Then
		UpdateListOfCostGroups();
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts(ArrayOfDimensions);
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		GLAccountSettingsServer.UpdateSettingsPresentation(ThisObject, "Object." + TSName, ArrayOfRowIDs_);
	EndIf;
	If TSName = "ManufacturedProducts" Then
		FillParameters = ParametersAndDirectionOfActivity(Object);
		FillInActivityDirectionInTable(TSName, FillParameters, RowsArray);
	EndIf;
	If TSName = "ManufacturedProducts"
			And Object.Patch
			And Object.CorrectionSavesProductionLots
		Or TSName = "SideAndIntermediateRelease"
		Or TSName = "MaterialsAndWorks"
		Or TSName = "LaborCosts" Then
		
		SetDefaultCostGroupNumberOnServer(TSName, RowsCollection);
		
		If TSName = "LaborCosts" Then
			FillInDefaultSubdivisionInCollection(RowsCollection);
			FillInTypeOfContractor(RowsCollection);
		EndIf;
		
	EndIf;
	
	SetProductGroupHeaders(ThisObject, TSName);
	
	If TSName = "MaterialsAndWorks" Then
		
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
		
	EndIf;
	
	If TSName = "MaterialsAndWorks" Then
		FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(
	TSName, Form, StructureOfActions, RecalculateNumberOfUnits = False, FillInTheDepartment = False)
	
	Object = Form.Object;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	StructureOfActions.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		Form.FormName, TSName));
		
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("CheckFillInCostShare", Form.CostAllocationParameters);
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		
		If (TSName = "ManufacturedProducts" And Form.UseTargetCost)
			Or Not TSName = "ManufacturedProducts" Then
			
			ParametersStructure = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object);
			ParametersStructure.Insert("PriceKind", Object.PriceKind);
			StructureOfActions.Insert("FillInSalePrice", ParametersStructure);
			StructureOfActions.Insert("RecalculateAmount", "Count");
				
		EndIf;
		
	EndIf;
	
	If TSName = "MaterialsAndWorks" Then
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			Form, "Products", StructureOfActions);
	EndIf;
	
	AddReleaseDirectionActionsToStructure(TSName, Form, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(TSName, Form, StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	If TSName = "ManufacturedProducts" Then
		StructureOfActions.Insert("RecalculateCostShare", Form.CostAllocationParameters);
	EndIf;
	If TSName = "SideAndIntermediateRelease"
		Or (TSName = "ManufacturedProducts" And Form.UseTargetCost) Then
		StructureOfActions.Insert("RecalculateAmount");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddSeriesActionsToStructure(StructureOfActions, Warehouse, SeriesSpecificationParameters)
	
	SeriesVerificationParameters = New Structure("Warehouse, SeriesSpecificationParameters", Warehouse, SeriesSpecificationParameters);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddReleaseDirectionActionsToStructure(TSName, Form, StructureOfActions)

	If TSName <> "ManufacturedProducts" And TSName <> "SideAndIntermediateRelease" Then 
		Return;
	EndIf;
	
	StructureOfActions.Insert("FillInReleaseDirection", New Structure);
	StructureOfActions.FillInReleaseDirection.Insert("UseWriteOffForExpenses");
		
	FillPropertyValues(StructureOfActions.FillInReleaseDirection, Form);
	
	AddRecipientActionsToStructure(TSName, Form, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddRecipientActionsToStructure(TSName, Form, StructureOfActions)

	If TSName <> "ManufacturedProducts" And TSName <> "SideAndIntermediateRelease" Then 
		Return;
	EndIf;
	
	StructureOfActions.Insert("FillOutRecipientInDirectionOfIssue", New Structure);
	StructureOfActions.FillOutRecipientInDirectionOfIssue.Insert("Department");
	StructureOfActions.FillOutRecipientInDirectionOfIssue.Insert("UseSeveralWarehouses");
	StructureOfActions.FillOutRecipientInDirectionOfIssue.Insert("DefaultWarehouse");
	
	FillPropertyValues(StructureOfActions.FillOutRecipientInDirectionOfIssue, Form.Object, "Department");
			
	FillPropertyValues(StructureOfActions.FillOutRecipientInDirectionOfIssue, Form, 
																	"UseSeveralWarehouses, DefaultWarehouse");

EndProcedure		

&AtClientAtServerNoContext
Procedure AddWarehouseActionsToStructure(TSName, Form, StructureOfActions)
	
	If TSName <> "MaterialsAndWorks" Then
		Return;
	EndIf;
	
	ProductionClientServer.AddToStructureActionsCheckFillProductionWarehouse(Form.Object.Department, StructureOfActions);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddShopPantryActionsToStructure(
			TSName, StructureOfActions, RecalculateNumberOfUnits = False, FillInTheDepartment = False)
	
	If TSName = "MaterialsAndWorks" Then
		WarehouseFieldName = "Warehouse";
	ElsIf TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		WarehouseFieldName = "Recipient";
	Else
		Return;
	EndIf;	
	
	StructureOfActions.Insert("FillInShopPantryAttribute", New Structure);
	StructureOfActions.FillInShopPantryAttribute.Insert("WarehouseFieldName", WarehouseFieldName);
	StructureOfActions.FillInShopPantryAttribute.Insert("FillInTheDepartment", FillInTheDepartment);
	
	If RecalculateNumberOfUnits Then
		StructureOfActions.Insert(
			"RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureToFillInArticleAndAnalytics(TSName, Form, StructureOfActions, CurrentRow)
	
	If Not TSName = "ManufacturedProducts"
		And Not TSName = "SideAndIntermediateRelease" Then
		Return;
	EndIf;
	
	Object = Form.Object;
	
	If Not CurrentRow = Undefined
		And ValueIsFilled(CurrentRow.DirectionOfProductionIssue)
		And Not CurrentRow.DirectionOfProductionIssue = PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse") Then
		
		IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics(
			StructureOfActions,
			Form,
			"Object." + TSName,
			"Recipient");
		
		IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
			StructureOfActions,
			Form,
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
			Object.Organization,
			Object.Department,
			"Object." + TSName,
			"Recipient");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region GroupCosts

&AtServer
Procedure AddChangeCostGroup(String)
	
	If Object.Patch
		And Object.CorrectionSavesProductionLots Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = CostGroupSearchStructure(String);
	CostGroupPresentation = CostGroupPresentation(TheStructureOfTheSearch, Object.GroupCosts);
	
	GroupNumberBeforeChange = String.CostGroupNumber;
	
	CostGroupDescription = CostGroupDescription(TheStructureOfTheSearch);
	NumberOfGroup = CostGroupDescription.CostGroupNumber;
	LineOfBusiness = CostGroupDescription.LineOfBusiness;
	InternalSubcontracting = CostGroupDescription.InternalSubcontracting;
	MaterialProviderCompany    = CostGroupDescription.MaterialProviderCompany;
	If NumberOfGroup = 0 Then
		
		NewCostGroup = ListOfGroups.Add();
		FillPropertyValues(NewCostGroup, TheStructureOfTheSearch);
		
		MaximumNumberOfCostGroup = MaximumNumberOfCostGroup + 1;
		
		NewCostGroup.CostGroupNumber = MaximumNumberOfCostGroup;
		NewCostGroup.ExpenseGroup = CostGroupPresentation;
		
		If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
			Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches
			Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments Then
			LineOfBusiness = Common.ObjectAttributeValue(NewCostGroup.Purpose, "LineOfBusiness");
			NewCostGroup.LineOfBusiness = LineOfBusiness;
		EndIf;
		
		NumberOfGroup = NewCostGroup.CostGroupNumber;
		InternalSubcontracting = NewCostGroup.InternalSubcontracting;
		MaterialProviderCompany = NewCostGroup.MaterialProviderCompany;
	EndIf;
	
	CostGroupDescription = New Structure;
	CostGroupDescription.Insert("CostGroupNumber", NumberOfGroup);
	CostGroupDescription.Insert("ExpenseGroup", CostGroupPresentation);
	CostGroupDescription.Insert("LineOfBusiness", LineOfBusiness);
	CostGroupDescription.Insert("InternalSubcontracting", InternalSubcontracting);
	CostGroupDescription.Insert("MaterialProviderCompany", MaterialProviderCompany);
	If Not GroupNumberBeforeChange = NumberOfGroup Then
		
		If NumberOfIdentifyingRows(GroupNumberBeforeChange) = 1 Then
			
			If Not GroupNumberBeforeChange = 0
				Or ListOfGroups.Count() = 1 Then
				UpdateLinksToCostGroup(GroupNumberBeforeChange, CostGroupDescription);
			EndIf;
			
			TheStructureOfTheSearch = New Structure("CostGroupNumber", GroupNumberBeforeChange);
			
			CostGroups = ListOfGroups.FindRows(TheStructureOfTheSearch);
			For Each CurGroup In CostGroups Do
				ListOfGroups.Delete(CurGroup);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	String.CostGroupNumber = NumberOfGroup;
	String.ExpenseGroup = CostGroupPresentation;
	
EndProcedure

&AtServer
Procedure DeleteCostGroup(RowID)
	
	String = Object.ManufacturedProducts.FindByID(RowID);
	
	If NumberOfIdentifyingRows(String.CostGroupNumber) = 1 Then
		
		CostGroupDescription = New Structure;
		CostGroupDescription.Insert("CostGroupNumber", 0);
		CostGroupDescription.Insert("ExpenseGroup", "");
		CostGroupDescription.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
		CostGroupDescription.Insert("InternalSubcontracting", False);
		CostGroupDescription.Insert("MaterialProviderCompany", Catalogs.Companies.EmptyRef());
		UpdateLinksToCostGroup(String.CostGroupNumber, CostGroupDescription);
		
		TheStructureOfTheSearch = New Structure("CostGroupNumber", String.CostGroupNumber);
		
		CostGroups = ListOfGroups.FindRows(TheStructureOfTheSearch);
		For Each CurGroup In CostGroups Do
			ListOfGroups.Delete(CurGroup);
		EndDo;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetDefaultCostGroupNumber(TSName)
	
	If ListOfGroups.Count() = 1 Then
		
		CurrentData = Items[TSName].CurrentData;
		SetDefaultCostGroupNumberOnClientOnServerWithoutContext(TSName, CurrentData, ListOfGroups[0]);
		If TSName = "SideAndIntermediateRelease" Then
			StructureOfActions = New Structure;
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDefaultCostGroupNumberOnServer(TSName, RowsArray)
	
	If ListOfGroups.Count() = 1 Then
		RowsToProcess = New Array;
		For Each CurrentData In RowsArray Do
			SetDefaultCostGroupNumberOnClientOnServerWithoutContext(TSName, CurrentData, ListOfGroups[0]);
			If TSName = "SideAndIntermediateRelease" Then
				RowsToProcess.Add(CurrentData);
			EndIf;
		EndDo;
		If TSName = "SideAndIntermediateRelease"
			And ValueIsFilled(RowsToProcess) Then
			StructureOfActions = New Structure;
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
			BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object[TSName]);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetDefaultCostGroupNumberOnClientOnServerWithoutContext(TSName, CurrentData, CostGroupDescription)
	
	If Not CurrentData = Undefined
		And CurrentData.CostGroupNumber = 0 Then
		
		CurrentData.ExpenseGroup = CostGroupDescription.ExpenseGroup;
		CurrentData.CostGroupNumber = CostGroupDescription.CostGroupNumber;
		If TSName = "ManufacturedProducts"
			Or TSName = "SideAndIntermediateRelease" Then
			
			CurrentData.InternalSubcontracting = CostGroupDescription.InternalSubcontracting;
			CurrentData.MaterialProviderCompany = CostGroupDescription.MaterialProviderCompany;
			
			If TSName = "SideAndIntermediateRelease" Then
				
				CurrentData.ProductOwner = CurrentData.MaterialProviderCompany;
				
				If CurrentData.InternalSubcontracting
					And ValueIsFilled(CurrentData.MaterialProviderCompany) Then
					CurrentData.TextOwnerGiver = StrTemplate(NStr("vi = 'Người đặt gia công: %1';
																	|ru = 'Давалец: %1';
																	|en = 'Material provider: %1'; fa = 'Material provider: %1';
																	|it = 'Давалец: %1';
																	|pl = 'Material provider: %1';
																	|tr = 'Tedarikçi: %1'"), CurrentData.MaterialProviderCompany);
				Else
					CurrentData.TextOwnerGiver = "";
				EndIf;
				
			EndIf;
			
		EndIf;
		If Not TSName = "LaborCosts" Then
			CurrentData.LineOfBusiness = CostGroupDescription.LineOfBusiness;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateLinksToCostGroup(CurrentGroupNumber, CostGroupDescription)
	
	NewGroupPresentation		= CostGroupDescription.ExpenseGroup;
	NewGroupNumber				= CostGroupDescription.CostGroupNumber;
	NewDirectionOfActivity	= CostGroupDescription.LineOfBusiness;
	NewInternalRecycling		= CostGroupDescription.InternalSubcontracting;
	NewCompanyGiver			= CostGroupDescription.MaterialProviderCompany;
	TheStructureOfTheSearch = New Structure("CostGroupNumber", CurrentGroupNumber);
	RowsArray = New Array;
	Rows = Object.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch);
	For Each CurRow In Rows Do
		
		CurRow.ExpenseGroup = NewGroupPresentation;
		CurRow.CostGroupNumber = NewGroupNumber;
		CurRow.LineOfBusiness = NewDirectionOfActivity;
		CurRow.InternalSubcontracting = NewInternalRecycling;
		CurRow.MaterialProviderCompany = NewCompanyGiver;
		CurRow.ProductOwner = CurRow.MaterialProviderCompany;
		
		If CurRow.InternalSubcontracting
			And ValueIsFilled(CurRow.MaterialProviderCompany) Then
			CurRow.TextOwnerGiver = StrTemplate(NStr("vi = 'Người đặt gia công: %1';
													|ru = 'Давалец: %1';
													|en = 'Material provider: %1'; fa = 'Material provider: %1';
													|it = 'Давалец: %1';
													|pl = 'Material provider: %1';
													|tr = 'Tedarikçi: %1'"), CurRow.MaterialProviderCompany);
		Else
			CurRow.TextOwnerGiver = "";
		EndIf;
		
		RowsArray.Add(CurRow);
	EndDo;
	If ValueIsFilled(RowsArray) Then
		StructureOfActions = New Structure;
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		BatchProcessingOfTablePartServer.ProcessTSStrings(RowsArray, StructureOfActions, Object.SideAndIntermediateRelease);
	EndIf;
	Rows = Object.MaterialsAndWorks.FindRows(TheStructureOfTheSearch);
	For Each CurRow In Rows Do
		CurRow.ExpenseGroup = NewGroupPresentation;
		CurRow.CostGroupNumber = NewGroupNumber;
		CurRow.LineOfBusiness = NewDirectionOfActivity;
	EndDo;
	
	Rows = Object.LaborCosts.FindRows(TheStructureOfTheSearch);
	For Each CurRow In Rows Do
		CurRow.ExpenseGroup = NewGroupPresentation;
		CurRow.CostGroupNumber = NewGroupNumber;
	EndDo;
	
EndProcedure

&AtServer
Function CostGroupDescription(TheStructureOfTheSearch)

	CostGroupDescription = New Structure;
	CostGroupDescription.Insert("CostGroupNumber", 0);
	CostGroupDescription.Insert("ExpenseGroup", "");
	CostGroupDescription.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	CostGroupDescription.Insert("InternalSubcontracting", False);
	CostGroupDescription.Insert("MaterialProviderCompany", Catalogs.Companies.EmptyRef());
	ExpenseGroup = ListOfGroups.FindRows(TheStructureOfTheSearch);
	
	If Not ExpenseGroup.Count() = 0 Then
		FillPropertyValues(CostGroupDescription, ExpenseGroup[0]);
	EndIf;
	
	Return CostGroupDescription;

EndFunction

&AtServer
Function CostGroupSearchStructure(String)
	
	FieldList = Documents.BackflushProduction.ListOfCostGroupFields(Object.GroupCosts);
	TheStructureOfTheSearch = Documents.BackflushProduction.CostGroupSearchStructure(FieldList);
	
	If Not String = Undefined Then
		FillPropertyValues(TheStructureOfTheSearch, String);
	EndIf;
	
	Return TheStructureOfTheSearch;
	
EndFunction

&AtServer
Function NumberOfIdentifyingRows(NumberOfGroup)
	
	TheStructureOfTheSearch = New Structure("CostGroupNumber", NumberOfGroup);
	Rows = Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch);
	
	Return Rows.Count();
	
EndFunction

&AtServer
Procedure UpdateListOfCostGroups()

	FieldList = Documents.BackflushProduction.ListOfCostGroupFields(Object.GroupCosts);
	
	TextOfSelectionFieldTt = Documents.BackflushProduction.RequestTextByCostGroupFields("DataTable", FieldList);
	TextOfSelectionField = TextOfSelectionFieldTt;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT 
	|	DataTable.CostGroupNumber
	|	,&TextOfSelectionFieldTt
	|INTO TT_CostGroups
	|FROM
	|	&DataTable AS DataTable
	|WHERE
	|	&Filter
	|;
	|/////////////////////////////////////////////////////
	|
	|SELECT
	|	DataTable.CostGroupNumber
	|	,&TextOfSelectionField
	|FROM
	|	TT_CostGroups AS DataTable
	|;
	|/////////////////////////////////////////////////////
	|
	|SELECT
	|	MAX(TT_CostGroups.CostGroupNumber) AS CostGroupNumber
	|FROM
	|	TT_CostGroups AS TT_CostGroups
	|";
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignments
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductsAndAssignmentsWithoutBatches
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments Then
		TextOfSelectionField = TextOfSelectionField +
			", CAST(DataTable.Purpose AS Catalog.Assignments).LineOfBusiness AS LineOfBusiness";
	EndIf;
	
	If Object.Patch
		And Object.CorrectionSavesProductionLots Then
		Query.Text = StrReplace(Query.Text, "&DataTable", "Document.BackflushProduction.ManufacturedProducts");
		Query.Text = StrReplace(Query.Text, "&Filter", "DataTable.Ref = &Ref");
		Query.SetParameter("Ref", Object.CorrectedDocument);
	Else
		Query.Text = StrReplace(Query.Text, "&Filter", "TRUE");
		Query.SetParameter("DataTable", Object.ManufacturedProducts.Unload());
	EndIf;
	
	Query.Text = StrReplace(Query.Text, ",&TextOfSelectionFieldTt", TextOfSelectionFieldTt);
	Query.Text = StrReplace(Query.Text, ",&TextOfSelectionField", TextOfSelectionField);
	Result = Query.ExecuteBatch();
	
	ListOfGroups.Load(Result[1].Unload());
	
	If Not Result[2].IsEmpty() Then
		Selection = Result[2].Select();
		Selection.Next();
		MaximumNumberOfCostGroup = Selection.CostGroupNumber;
	EndIf;
	
	UpdateCostGroupPresentation();
	
EndProcedure

&AtServer
Procedure UpdateCostGroupPresentation()
	
	TheStructureOfTheSearch = New Structure("CostGroupNumber");
	
	For Each CurGroup In ListOfGroups Do
		
		CurGroup.ExpenseGroup = CostGroupPresentation(CurGroup, Object.GroupCosts);
		
		FillPropertyValues(TheStructureOfTheSearch, CurGroup);
		
		Rows = Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch);
		For Each CurRow In Rows Do
			
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
			
			If Object.Patch
				And Object.CorrectionSavesProductionLots Then
				
				CurRow.LineOfBusiness = CurGroup.LineOfBusiness;
				CurRow.InternalSubcontracting = CurGroup.InternalSubcontracting;
				CurRow.MaterialProviderCompany = CurGroup.MaterialProviderCompany;
			EndIf;
			
		EndDo;
		
		Rows = Object.SideAndIntermediateRelease.FindRows(TheStructureOfTheSearch);
		For Each CurRow In Rows Do
			
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
			CurRow.LineOfBusiness = CurGroup.LineOfBusiness;
			CurRow.InternalSubcontracting = CurGroup.InternalSubcontracting;
			CurRow.MaterialProviderCompany = CurGroup.MaterialProviderCompany;
			
			If CurRow.InternalSubcontracting
				And ValueIsFilled(CurRow.MaterialProviderCompany) Then
				CurRow.TextOwnerGiver = StrTemplate(NStr("vi = 'Người đặt gia công: %1';
														|ru = 'Давалец: %1';
														|en = 'Material provider: %1'; fa = 'Material provider: %1';
														|it = 'Давалец: %1';
														|pl = 'Material provider: %1';
														|tr = 'Tedarikçi: %1'"), CurRow.MaterialProviderCompany);
			Else
				CurRow.TextOwnerGiver = "";
			EndIf;
		EndDo;
		
		Rows = Object.MaterialsAndWorks.FindRows(TheStructureOfTheSearch);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
			CurRow.LineOfBusiness = CurGroup.LineOfBusiness;
		EndDo;
		
		Rows = Object.LaborCosts.FindRows(TheStructureOfTheSearch);
		For Each CurRow In Rows Do
			CurRow.ExpenseGroup = CurGroup.ExpenseGroup;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Function CostGroupPresentation(Var_Group, GroupCosts)
	
	GroupPresentation = "";
	
	CostGroupFields_ = Documents.BackflushProduction.ListOfCostGroupFields(Object.GroupCosts);
	
	For Each CurField In CostGroupFields_ Do
		If CurField.Value = "InternalSubcontracting" Then
			Continue;
		EndIf;
		CurPresentation = String(Var_Group[CurField.Value]);
		If ValueIsFilled(CurPresentation) Then
			GroupPresentation = GroupPresentation + CurPresentation + " / ";
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(GroupPresentation) Then
		GroupPresentation = Left(GroupPresentation, StrLen(GroupPresentation) - 3);
	Else
		GroupPresentation = NStr("vi = '<nhóm có giá trị trống>';
								|ru = '<группа с пустыми значениями>';
								|en = '<group with empty values>'; fa = '<group with empty values>';
								|it = '<gruppo con valori vuoti>';
								|pl = '<grupa z pustymi wartościami>';
								|tr = '<boş değerli grup>'");
	EndIf;
	
	Return GroupPresentation;

EndFunction 

&AtServer
Function CostGroupStorageAddress()
	
	Return PutToTempStorage(ListOfGroups.Unload(), ThisForm.UUID);
	
EndFunction

#EndRegion

#Region Substitutes

&AtServer
Procedure NotePresenceOfAnalogues()

	TSName = "MaterialsAndWorks";
	AlternativeMaterials.NotePresenceOfAnalogues(Object[TSName], AnalogSelectionParameters(TSName, 0));

EndProcedure

&AtClient
Procedure OpenSelectionOfAnalogues()
	
	TSName = "MaterialsAndWorks";
	
	WarningText = "";
	
	SelectedRows = Items[TSName].SelectedRows;
	
	SelectedLinesNumber = SelectedRows.Count();
	If SelectedLinesNumber = 0 Then
		
		WarningText = NStr("vi = 'Cần chọn (các) dòng';
							|ru = 'Необходимо выделить строку(и).';
							|en = 'Highlight the line(s).'; fa = 'Highlight the line(s).';
							|it = 'Необходимо выделить строку(и).';
							|pl = 'Highlight the line(s).';
							|tr = 'Satır(lar) vurgulanmalıdır.'");
		
	ElsIf SelectedLinesNumber > 1 Then
		
		SelectedWarehouses = New Map;
		For Each RowID In SelectedRows Do
			
			CurrentRow = Object[TSName].FindByID(RowID);
			
			SelectedWarehouses.Insert(CurrentRow.Warehouse);
			If SelectedWarehouses.Count() > 1 Then
				WarningText = NStr("vi = 'Cần chọn các dòng có kho giống nhau.';
									|ru = 'Необходимо выбрать строки с одинаковым складом.';
									|en = 'Select lines with the same warehouse.'; fa = 'Select lines with the same warehouse.';
									|it = 'Необходимо выбрать строки с одинаковым складом.';
									|pl = 'Select lines with the same warehouse.';
									|tr = 'Aynı ambara sahip satırların seçilmesi gerekmektedir.'");
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(WarningText) Then
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	AlternativeMaterialsClient.OpenSelectionOfAnalogues(AnalogSelectionParameters(TSName, 1), ThisObject);
	
EndProcedure

&AtServer
Procedure Replace_With_Analogues(AddressInStorage = Undefined)
	
	TSName = "MaterialsAndWorks";
	AdditionalFields = "CostGroupNumber, ExpenseGroup, Department, ProductCostElement";
	
	Result = AlternativeMaterials.PerformReplacementForAnalogues(Object[TSName], AddressInStorage, AdditionalFields, True);
	
	IndexesOfModifiedRows = Result.IndexesOfModifiedRows;
	IndexesOfNewRows = Result.IndexesOfNewRows;
	
	NumberOfReplacementsMade = IndexesOfModifiedRows.Count() + IndexesOfNewRows.Count();
	MessageText  = StrTemplate(NStr("vi = 'Dòng được thay đổi: %1';
									|ru = 'Измененных строк: %1';
									|en = 'Changed lines: %1'; fa = 'Changed lines: %1';
									|it = 'Измененных строк: %1';
									|pl = 'Changed lines: %1';
									|tr = 'Değiştirilen satırlar: %1'"), NumberOfReplacementsMade);
	Common.MessageToUser(MessageText);

	If NumberOfReplacementsMade = 0 Then
		Return;
	EndIf;
	
	Modified = True;
	
	RowsIDs = New Array;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisObject, StructureOfActions);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array;
	For Each RowIndex In IndexesOfModifiedRows Do
		
		CurrentRow = Object[TSName][RowIndex];
		RowsToProcess.Add(CurrentRow);
		RowsIDs.Add(CurrentRow.GetID());
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName],
		CachedValues);

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True, True);
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True, True);
	
	RowsToProcess = New Array;
	For Each RowIndex In IndexesOfNewRows Do
		
		CurrentRow = Object[TSName][RowIndex];
		RowsToProcess.Add(CurrentRow);
		RowsIDs.Add(CurrentRow.GetID());
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName],
		CachedValues);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsIDs, StructureOfActions);
	
EndProcedure

// Generates parameters for selecting analogs
//
// Parameters:
//	TSName - String - Name of the table to be processed
//	Mode - Number  - 0-show analogs
//                   1 - choose the analogues
//                   2-replace with analogs
// 
// Returns:
//  Structure - See AlternativeMaterials.AnalogSelectionParameters
//
&AtServer
Function AnalogSelectionParameters(TSName, Mode)
	
	SourceType = Common.TypeDescriptionNumber(10, 0, AllowedSign.Nonnegative);
	FormParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	// GeneralParameters
	FormParameters.GeneralParameters.ShowBalance = True;
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", SourceType);
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument Then
		FieldsStructure.DefaultValues.Insert("Ref", 0);
	Else
		FieldsStructure.SpoofFields.Insert("Ref", "CostGroupNumber");
	EndIf;
	
	If Mode = 1 Then
		
		ArrayOfSelectedRows = New Array;
	
		SelectedRows = Items[TSName].SelectedRows;
		For Each RowID In SelectedRows Do
			ArrayOfSelectedRows.Add(Object[TSName].FindByID(RowID));
		EndDo;
		
		TableOfGoods = Object[TSName].Unload(ArrayOfSelectedRows);
		
	Else	
		
		TableOfGoods = Object[TSName].Unload();
		
	EndIf;
	
	TableOfGoods.Columns.Add("WithAssignment", New TypeDescription("Boolean"));
	For Each RowOfGoods In TableOfGoods Do
		RowOfGoods.WithAssignment = ValueIsFilled(RowOfGoods.Purpose);
	EndDo;
	
	ObjectName = "Object";
	FormData1 = New Structure;
	FormData1.Insert("Items", Items);
	FormData1.Insert("UUID", UUID);
	FormData1.Insert(ObjectName, New Structure);
	FormData1[ObjectName].Insert(TSName, TableOfGoods);
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		FormData1, "Object", TSName, Mode, False, FieldsStructure);
	
	FillPropertyValues(FormParameters.GoodsParameters, ProductData_9);;
	
	// SubstitutesParameters
	SubstitutesParameters = FormParameters.SubstitutesParameters;
	
	ParametersTable = SubstitutesParameters.ParametersTable;
	
	CurrentValidityDateOfPermissions  = BegOfDay(CurrentSessionDate());
	CurrentDepartment           = Object.Department;
	CurrentDirectionOfActivity = Object.LineOfBusiness;
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument Then
		
		TableRow = ParametersTable.Add();
		TableRow.PermissionValidityDate  = CurrentValidityDateOfPermissions;
		TableRow.Ref                  = 0;
		TableRow.Department           = CurrentDepartment;
		TableRow.LineOfBusiness = CurrentDirectionOfActivity;
		
	Else
		
		QueryTextSourceTables =
		"SELECT
		|	MaterialsAndWorks.CostGroupNumber AS CostGroupNumber
		|INTO MaterialsAndWorks
		|FROM
		|	&MaterialsAndWorks AS MaterialsAndWorks
		|
		|INDEX BY
		|	CostGroupNumber
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ManufacturedProducts.CostGroupNumber AS CostGroupNumber,
		|	&Fields
		|INTO ManufacturedProducts
		|FROM
		|	&ManufacturedProducts AS ManufacturedProducts
		|
		|INDEX BY
		|	CostGroupNumber";
		
		If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments
		 Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM Then
			
			QueryText =
			"SELECT
			|	MaterialsAndWorks.CostGroupNumber                           AS CostGroupNumber,
			|	ISNULL(ManufacturedProducts.BillOfMaterials,
			|		VALUE(Catalog.BillsOfMaterials.EmptyRef)) AS BillOfMaterials
			|FROM
			|	MaterialsAndWorks AS MaterialsAndWorks
			|		LEFT JOIN ManufacturedProducts AS ManufacturedProducts
			|		ON MaterialsAndWorks.CostGroupNumber = ManufacturedProducts.CostGroupNumber";
			
			ColumnsOutputProducts = "BillOfMaterials";
			
		Else
			
			QueryText =
			"SELECT
			|	MaterialsAndWorks.CostGroupNumber                                AS CostGroupNumber,
			|	ISNULL(ManufacturedProducts.Products,
			|		VALUE(Catalog.Products.EmptyRef))               AS Product,
			|	ISNULL(ManufacturedProducts.Characteristic,
			|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS ItemVariantOfProduct
			|FROM
			|	MaterialsAndWorks AS MaterialsAndWorks
			|		LEFT JOIN ManufacturedProducts AS ManufacturedProducts
			|		ON MaterialsAndWorks.CostGroupNumber = ManufacturedProducts.CostGroupNumber";
			
			ColumnsOutputProducts = "Products, Characteristic";
			
		EndIf;
		
		QueryTexts = New Array;
		QueryTexts.Add(StrReplace(QueryTextSourceTables, "&Fields", ColumnsOutputProducts));
		QueryTexts.Add(QueryText);
		
		RowsArray = Undefined;
		
		If Mode = 1 Then
			
			RowsArray = New Array;
			
			SelectedRows = Items[TSName].SelectedRows;
			For Each RowID In SelectedRows Do
				RowsArray.Add(Object[TSName].FindByID(RowID));
			EndDo;
			
		EndIf;
		
		Query = New Query;
		Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
		
		Query.SetParameter(
			"MaterialsAndWorks",
			Object.MaterialsAndWorks.Unload(RowsArray, "CostGroupNumber"));
		
		Query.SetParameter(
			"ManufacturedProducts", 
			Object.ManufacturedProducts.Unload(, StrTemplate("CostGroupNumber, %1", ColumnsOutputProducts)));
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			TableRow = ParametersTable.Add();
			TableRow.PermissionValidityDate  = CurrentValidityDateOfPermissions;
			TableRow.Ref                  = Selection.CostGroupNumber;
			TableRow.Department           = CurrentDepartment;
			TableRow.LineOfBusiness = CurrentDirectionOfActivity;
			
			FillPropertyValues(TableRow, Selection);
			
		EndDo;
		
	EndIf;
	
	SubstitutesParameters.ParametersTable = PutToTempStorage(ParametersTable, UUID);
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region FillType

&AtServer
Function FillInPricesByPriceKindServer(TSName = "")
	
	Cancel = False;
	LinesToReFill = Undefined;
	
	If Not IsBlankString(TSName) Then
	
		SelectedRows = Items[TSName].SelectedRows;
		If SelectedRows.Count() = 0 Then
			
			If TSName = "ManufacturedProducts" Then
				MessageText = NStr("vi = 'Trong bảng ""Sản phẩm đầu ra"" chưa chọn dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Выходные изделия"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the ""Finished products"" table.
										|Prices cannot be filled in.'; fa = 'No rows were selected in the ""Finished products"" table.
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Prodotti finiti"" non è stata selezionata nessuna riga. 
										| I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Produkty wyjściowe"" nie wybrano ani jednego wiersza.
										|Nie można wypełnić cen.';
										|tr = '""Üretilen Nihai Ürünler"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			Else
				MessageText = NStr("vi = 'Trong bảng ""Sản phẩm phụ"" chưa chọn dòng nào. 
										|Không thể điền đơn giá.';
										|ru = 'В таблице ""Побочные изделия"" не выбрано ни одной строки. 
										|Цены не могут быть заполнены.';
										|en = 'No rows were selected in the By-products table. 
										|Prices cannot be filled in.'; fa = 'No rows were selected in the By-products table. 
										|Prices cannot be filled in.';
										|it = 'Nella tabella ""Sottoprodotti"" non è stata selezionata alcuna riga.
										|I prezzi non possono essere compilati.';
										|pl = 'W tabeli ""Produkty uboczne"" nie wybrano ani jednego wiersza.
										|Nie można wypełnić cen.';
										|tr = '""Yan Nihai Ürünler"" tablosunda herhangi bir satır seçilmedi.
										|Fiyatlar doldurulamaz.'");
			EndIf;
			
			Common.MessageToUser(MessageText,, TSName, "Object", Cancel);
			
		EndIf;
	
		If Not ValueIsFilled(Object.PriceKind) Then
			
			MessageText = NStr("vi = 'Trường ""Dạng giá"" không được điền.';
								|ru = 'Не заполнено поле ""Вид цены"".';
								|en = '""Price type"" is required.'; fa = '""Price type"" is required.';
								|it = 'Il campo ""Tipo di prezzo"" non è compilato.';
								|pl = 'Nie wypełniono pole ""Rodzaj ceny""';
								|tr = '""Fiyat Türü"" alanı doldurulmadı.'");
			Common.MessageToUser(MessageText,, "PriceKind", "Object", Cancel);
			
		EndIf;

		LinesToReFill = New Array;
		For Each RowID In Items[TSName].SelectedRows Do
			LinesToReFill.Add(Object[TSName].FindByID(RowID));
		EndDo;
	
	EndIf;
	
	If Cancel Then
		Return False;
	EndIf;
	
	TablesToRecalculate = New Array;
	TablesToRecalculate.Add("SideAndIntermediateRelease");
	If UseTargetCost Then
		TablesToRecalculate.Add("ManufacturedProducts");
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("Date",			Object.Date);
	FillParameters.Insert("Organization",		Object.Organization);
	FillParameters.Insert("Currency",			Object.Currency);
	FillParameters.Insert("PriceKind",			Object.PriceKind);
	FillParameters.Insert("PopulationFields",	"Price");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	
	PricesCalculated = True;
	For Each TableForRecalculation In TablesToRecalculate Do
		
		If Not IsBlankString(TSName) And Not TableForRecalculation = TSName Then
			Continue;
		EndIf;
		
		PricesCalculated = Min(PricesCalculated,
			EnterprisePricesFillingServer.FillInPrices(
				Object[TableForRecalculation],
				LinesToReFill,
				FillParameters,
				StructureOfActions));
		
	EndDo;
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure FillInPlanningCalculationsAndPricesOnServer(RowsIDs = Undefined, StandardCostEstimate = Undefined)
	
	If RowsIDs = Undefined Then
		Return;
	EndIf;
		
	CostGroupNumbers = New Array();
	For Each Id In RowsIDs Do
		RowOfProduct = Object.ManufacturedProducts.FindByID(Id);
		CostGroupNumbers.Add(RowOfProduct.CostGroupNumber);
	EndDo;
	
	CostGroupNumbers = CommonClientServer.CollapseArray(CostGroupNumbers);
	RowsArray = New Array;
	For Each IconNumberOfExpenseGroup In CostGroupNumbers Do
		ProductLines_2 = Object.ManufacturedProducts.FindRows(New Structure("CostGroupNumber", IconNumberOfExpenseGroup));
		CommonClientServer.SupplementArray(RowsArray, ProductLines_2);
	EndDo;
	
	FillParameters = Documents.StandardCosting2_2.DescriptionOfPriceFillingParameterInCollection();
	FillParameters.DocumentDate = Object.Date;
	FillParameters.DocumentCurrency = DocumentCurrency;
	FillParameters.StandardCostEstimate = StandardCostEstimate;
	
	Documents.StandardCosting2_2.FillInPricesByCalculationInCollection(
		Object.ManufacturedProducts,
		RowsArray,
		FillParameters);
	
EndProcedure
&AtClient
Procedure FillReleaseDirectionSelectionList(TSName, CurrentData)

	If TSName = "ManufacturedProducts" Then
		NameOfReleaseDirectionField = "ManufacturedProductsDirectionOfProductionIssue";
	Else
		NameOfReleaseDirectionField = "SideAndIntermediateReleaseDirectionOfProductionIssue";
	EndIf;
	
	ItemSelectionList = Items[NameOfReleaseDirectionField].ChoiceList;
	ItemSelectionList.Clear();
	
	If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		ItemSelectionList.Add(PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit"),
									NStr("vi = 'Sang bộ phận';
										|ru = 'В подразделение';
										|en = 'To business unit'; fa = 'To business unit';
										|it = 'Al reparto';
										|pl = 'Do działu';
										|tr = 'Departmana'"));
	Else
		ItemSelectionList.Add(PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse"),
									NStr("vi = 'Điều chuyển hàng hóa';
										|ru = 'На склад';
										|en = 'To warehouse'; fa = 'To warehouse';
										|it = 'Al magazzino';
										|pl = 'Na magazyn';
										|tr = 'Ambara'"));
	EndIf; 
	
	If UseWriteOffForExpenses Then
		ItemSelectionList.Add(PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand"),
									NStr("vi = 'Ghi giảm vào chi phí';
										|ru = 'Списать на расходы';
										|en = 'Expense as'; fa = 'هزینه به عنوان';
										|it = 'Stornare sulle spese';
										|pl = 'Spisać w koszty';
										|tr = 'Gider olarak kaydet'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure MaterialsAndWorksShouldBeSupplementedWithSeparateBalancesOnServer(CachedValues)
	
	Query = New Query;
	
	Query.Text = 
		"SELECT
		|	Assignments.Purpose AS Purpose
		|INTO AssignmentsTable
		|FROM
		|	&Assignments AS Assignments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN NOT CatGiverAppointments.Ref IS NULL
		|			THEN CatGiverAppointments.Ref
		|		WHEN TRUE
		|			THEN AssignmentsTable.Purpose
		|	END AS Purpose
		|INTO Assignments
		|FROM
		|	AssignmentsTable AS AssignmentsTable
		|
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|		ON AssignmentsTable.Purpose = CatAssignments.Ref
		|		AND CatAssignments.AssignmentType IN(
		|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|
		|		LEFT JOIN Catalog.Assignments AS CatGiverAppointments
		|		ON CatAssignments.Partner = CatGiverAppointments.Partner
		|		AND CatAssignments.Contract = CatGiverAppointments.Contract
		|
		|GROUP BY
		|	CASE
		|		WHEN NOT CatGiverAppointments.Ref IS NULL
		|			THEN CatGiverAppointments.Ref
		|		WHEN TRUE
		|			THEN AssignmentsTable.Purpose
		|	END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	&Organization								AS Organization,
		|	ItemsLocationAttributes.Products		AS Products,
		|	ItemsLocationAttributes.Characteristic	AS Characteristic,
		|	ItemsLocationAttributes.Series			AS Series,
		|	ISNULL(ItemsLocationAttributes.WarehouseArea.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
		|	ItemsLocationAttributes.StorageLocation	AS Warehouse,
		|	ISNULL(ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE) AS ShopFloorStockroom,
		|	Assignments.Purpose						AS Purpose,
		|	ItemsLocationAttributes.Ref			AS DimensionKey
		|INTO TTProductAccountingAnalytics_
		|FROM
		|	Assignments AS Assignments
		|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ItemsLocationAttributes
		|		ON (ItemsLocationAttributes.Purpose = Assignments.Purpose)
		|WHERE
		|	ItemsLocationAttributes.ProductCostElement = VALUE(Catalog.ProductCostElements.EmptyRef)
		|
		|GROUP BY
		|	ItemsLocationAttributes.Products,
		|	ISNULL(ItemsLocationAttributes.WarehouseArea.Department, VALUE(Catalog.BusinessStructure.EmptyRef)),
		|	ItemsLocationAttributes.StorageLocation,
		|	ISNULL(ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE),
		|	ItemsLocationAttributes.Ref,
		|	ItemsLocationAttributes.Characteristic,
		|	ItemsLocationAttributes.Series,
		|	Assignments.Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	&CostGroupNumber												AS CostGroupNumber,
		|	&ExpenseGroup													AS ExpenseGroup,
		|	TTProductAccountingAnalytics_.Department						AS Department,
		|	TTProductAccountingAnalytics_.Warehouse								AS Warehouse,
		|	TTProductAccountingAnalytics_.ShopFloorStockroom					AS ShopFloorStockroom,
		|	TTProductAccountingAnalytics_.Products						AS Products,
		|	TTProductAccountingAnalytics_.Characteristic						AS Characteristic,
		|	TTProductAccountingAnalytics_.Series								AS Series,
		|	TTProductAccountingAnalytics_.Purpose							AS Purpose,
		|	TTProductAccountingAnalytics_.Purpose.LineOfBusiness	AS LineOfBusiness,
		|	SUM(CompanyGoods.CountBalance)						AS Count,
		|	SUM(CompanyGoods.CountBalance)						AS NumberOfPackages
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|			,
		|			(ItemsLocationAttributes, Organization) IN
		|				(SELECT
		|					TTProductAccountingAnalytics_.DimensionKey,
		|					TTProductAccountingAnalytics_.Organization
		|				FROM
		|					TTProductAccountingAnalytics_ AS TTProductAccountingAnalytics_)) AS CompanyGoods
		|		LEFT JOIN TTProductAccountingAnalytics_ AS TTProductAccountingAnalytics_
		|		ON (TTProductAccountingAnalytics_.DimensionKey = CompanyGoods.ItemsLocationAttributes)
		|
		|GROUP BY
		|	TTProductAccountingAnalytics_.Department,
		|	TTProductAccountingAnalytics_.Warehouse,
		|	TTProductAccountingAnalytics_.ShopFloorStockroom,
		|	TTProductAccountingAnalytics_.Series,
		|	TTProductAccountingAnalytics_.Products,
		|	TTProductAccountingAnalytics_.Characteristic,
		|	TTProductAccountingAnalytics_.Purpose
		|
		|HAVING
		|	SUM(CompanyGoods.CountBalance) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	&CostGroupNumber									AS CostGroupNumber,
		|	&ExpenseGroup										AS ExpenseGroup,
		|	Works.Department								AS Department,
		|	UNDEFINED										AS Warehouse,
		|	FALSE												AS ShopFloorStockroom,
		|	Works.Products									AS Products,
		|	Works.Characteristic								AS Characteristic,
		|	VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
		|	Works.Purpose									AS Purpose,
		|	Works.Purpose.LineOfBusiness			AS LineOfBusiness,
		|	SUM(Works.CountBalance)						AS Count,
		|	SUM(Works.CountBalance)						AS NumberOfPackages
		|FROM
		|	AccumulationRegister.MaterialsAndWorksInProduction.Balance(
		|			,
		|			(Organization, Products, Characteristic, Purpose) IN
		|				(SELECT
		|					TTProductAccountingAnalytics_.Organization,
		|					TTProductAccountingAnalytics_.Products,
		|					TTProductAccountingAnalytics_.Characteristic,
		|					TTProductAccountingAnalytics_.Purpose
		|				FROM
		|					TTProductAccountingAnalytics_ AS TTProductAccountingAnalytics_)) AS Works
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON (CatProducts.Ref = Works.Products)
		|WHERE
		|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|
		|GROUP BY
		|	Works.Department,
		|	Works.Products,
		|	Works.Characteristic,
		|	Works.Purpose
		|
		|HAVING
		|	SUM(Works.CountBalance) > 0";
		
	Assignments = Object.ManufacturedProducts.Unload(, "Purpose");
	Assignments.GroupBy("Purpose");
	
	LinesToDelete = Assignments.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
	For Each CurRow In LinesToDelete Do
		Assignments.Delete(CurRow);
	EndDo;
	
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Assignments", Assignments);
	
	CostGroupNumber = ?(ListOfGroups.Count() = 1, ListOfGroups[0].CostGroupNumber, 0);
	ExpenseGroup = ?(ListOfGroups.Count() = 1, ListOfGroups[0].ExpenseGroup, "");
	Query.SetParameter("CostGroupNumber", CostGroupNumber);
	Query.SetParameter("ExpenseGroup", ExpenseGroup);
	
	Selection = Query.Execute().Select();
	
	RowsArray = New Array;
	RowsToProcess = New Array();
	
	While Selection.Next() Do
		
		NewRow = Object.MaterialsAndWorks.Add();
		FillPropertyValues(NewRow, Selection);
		
		RowsArray.Add(NewRow.GetID());
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts("MaterialsAndWorks", ThisObject, StructureOfActions, True);
	AddWarehouseActionsToStructure("MaterialsAndWorks", ThisObject, StructureOfActions);
	AddShopPantryActionsToStructure("MaterialsAndWorks", StructureOfActions, True);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.MaterialsAndWorks,
		CachedValues);
	
	AfterChangingTSStringsProgrammaticallyOnServer("MaterialsAndWorks", RowsArray, StructureOfActions);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItem(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng mà muốn điền dạng chi phí';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить статью калькуляции.';
							|en = 'Select the lines for which it is required to populate the product cost element.'; fa = 'Select the lines for which it is required to populate the product cost element.';
							|it = 'È necessario selezionare le righe per le quali si deve compilare la voce di calcolo.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić pozycję kalkulacji.';
							|tr = 'Ürün maliyet kalemini doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	
	If TSName = "SideAndIntermediateRelease" Then
		
		FilterParameters.Insert("ExpenseType", PredefinedValue("Enum.CostTypes.RecyclableWaste"));
		
	ElsIf TSName = "MaterialsAndWorks" Then
		
		FilterParameters.Insert("ExpenseType", PredefinedValue("Enum.CostTypes.Material_"));
		
	ElsIf TSName = "LaborCosts" Then
		
		FilterParameters.Insert("ExpenseType", PredefinedValue("Enum.CostTypes.Payroll"));
		
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInTheCostingItemCompletion", ThisObject, TSName);
	
	OpenForm("Catalog.ProductCostElements.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItemCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		CurrentData.ProductCostElement = ClosingResult;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInPerformersCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.LaborCosts.SelectedRows;
	
	For Each RowID In SelectedRows Do
		CurrentData = Object.LaborCosts.FindByID(RowID);
		CurrentData.Performer = Result;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfForm()
	
	UseSeveralWarehouses = GetFunctionalOption("UseSeveralWarehouses");
	
	EstablishUseOfPlannedValue();
	FillDefaultWarehouse();
	FillInServiceDetailsForProductRange();
	
	ProductionServer.FillInShopPantryAttributeInTable(Object.ManufacturedProducts, "Recipient");
	ProductionServer.FillInShopPantryAttributeInTable(Object.SideAndIntermediateRelease, "Recipient");
	ProductionServer.FillInShopPantryAttributeInTable(Object.MaterialsAndWorks, "Warehouse");
	
	
	InternalSubcontractingServer.FillInProductOwnerIsAvailableInTable(ThisObject, Object.SideAndIntermediateRelease);
	FillParameters = ParametersAndDirectionOfActivity(Object);
	FillInActivityDirectionInTable("ManufacturedProducts", FillParameters);
	
	If RightToReadSubstitutes
	   And ShowAnalogues
	   And Object.GroupCosts <> Enums.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified Then
		NotePresenceOfAnalogues();
	EndIf;
	
	ProcessingOfTabularForms.InitializeRowCache(Items.ManufacturedProducts);
	ProcessingOfTabularForms.InitializeRowCache(Items.MaterialsAndWorks);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
											New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
											New Structure("Products", "SKU"));
	ParametersForFillingInBankingDetails.Insert("FillInProductTypeAttribute_",
											New Structure("Products", "ItemsType"));
											
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.ManufacturedProducts,
																			ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.SideAndIntermediateRelease,
																			ParametersForFillingInBankingDetails);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ParametersForFillingInBankingDetails);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.MaterialsAndWorks,
																			ParametersForFillingInBankingDetails);
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
EndProcedure

&AtServer
Procedure FillInDetailsOfOrganization()
	
	If ValueIsFilled(Object.Organization) Then
		
		LocalAccountingCurrency =
			SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		RegistrationCountry =
			Common.ObjectAttributeValue(Object.Organization, "RegistrationCountry");
			
	Else
		LocalAccountingCurrency = Undefined;
		RegistrationCountry = Undefined;
	EndIf;
	
EndProcedure
&AtServer
Procedure AddAccordingToSpecificationOnServer(TSName)
	
	Query = New Query;
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	If TSName = "MaterialsAndWorks" Then
		Query.Text = Documents.BackflushProduction.RequestTextMaterialsByCostGroup();
	ElsIf TSName = "SideAndIntermediateRelease" Then
		Query.Text = Documents.BackflushProduction.RequestTextReturnableWasteByCostGroup();
	Else
		Query.Text = Documents.BackflushProduction.RequestTextLaborCostsByCostGroup();
	EndIf;
	
	Query.SetParameter("Date", Object.Date);
	Query.SetParameter("PriceKind", Object.PriceKind);
	Query.SetParameter("AutoFill", True);
	
	// Let's prepare a table of products
	GroupFields = "CostGroupNumber, DirectionOfProductionIssue, Recipient,
							|	Products, Characteristic, Series,
							|	Purpose, LineOfBusiness, BillOfMaterials";
	SummationFields = "Count";
	
	ProductTable = Object.ManufacturedProducts.Unload(, GroupFields + ", " + SummationFields);
	ProductTable.GroupBy(GroupFields, SummationFields);
	
	ProductTable.Columns.Add("Organization",				New TypeDescription("CatalogRef.Companies"));
	ProductTable.Columns.Add("GroupCosts",			New TypeDescription("EnumRef.GroupingsOfCostsInBackflushProduction"));
	ProductTable.Columns.Add("Department",				New TypeDescription("CatalogRef.BusinessStructure"));
	ProductTable.Columns.Add("ErrorInModelSettings",	New TypeDescription("Boolean"));
	ProductTable.Columns.Add("RecordCostsByADocument",	New TypeDescription("Boolean"));
	
	ProductTable.FillValues(Object.Organization,			"Organization");
	ProductTable.FillValues(Object.GroupCosts,	"GroupCosts");
	ProductTable.FillValues(Object.Department,		"Department");
	ProductTable.FillValues(True,						"RecordCostsByADocument");
	
	// Prepare the filling parameters
	HeaderData_ = New Structure("Date", Object.Date);
	
	FillParameters = New Structure("HeaderData_",	HeaderData_);
	FillParameters.Insert("AutoFill",	True);
	
	ListOfData = New Array;
	If TSName = "SideAndIntermediateRelease" Then
		ListOfData.Add("RecyclableWaste");
	ElsIf TSName = "MaterialsAndWorks" Then
		ListOfData.Add("MaterialsAndServices");
	Else
		ListOfData.Add("LaborCosts");
	EndIf;
	FillParameters.Insert("ListOfData", ListOfData);
	
	// We will get the data of the specifications and put them in the VT.
	Documents.BackflushProduction.SpecificationDataForByManufacturedProductsList(
		ProductTable,
		FillParameters,
		TempTablesManager);
	
	// Fill in the costs
	CostTable = Query.Execute().Unload();
	
	If Not CostTable.Count() = 0 Then
		
		RowsArray = New Array;
		TheStructureOfTheSearch = New Structure("CostGroupNumber", 0);
		
		ObjectTable = Object[TSName]; // FormDataCollection
		RowsToProcess = New Array;
		For Each CurCost In CostTable Do
			
			NewRow = ObjectTable.Add();
			FillPropertyValues(NewRow, CurCost);
			
			TheStructureOfTheSearch.CostGroupNumber = NewRow.CostGroupNumber;
			ExpenseGroup = ListOfGroups.FindRows(TheStructureOfTheSearch);
			
			If Not ExpenseGroup.Count() = 0 Then
				
				GroupDetails = ExpenseGroup[0];
				NewRow.ExpenseGroup = GroupDetails.ExpenseGroup;
				If TSName = "SideAndIntermediateRelease" Then
					
					NewRow.InternalSubcontracting = GroupDetails.InternalSubcontracting;
					NewRow.MaterialProviderCompany = GroupDetails.MaterialProviderCompany;
					NewRow.ProductOwner = GroupDetails.MaterialProviderCompany;
					
					If NewRow.InternalSubcontracting
						And ValueIsFilled(NewRow.MaterialProviderCompany) Then
						NewRow.TextOwnerGiver = StrTemplate(NStr("vi = 'Người đặt gia công: %1';
																|ru = 'Давалец: %1';
																|en = 'Material provider: %1'; fa = 'Material provider: %1';
																|it = 'Давалец: %1';
																|pl = 'Material provider: %1';
																|tr = 'Tedarikçi: %1'"), NewRow.MaterialProviderCompany);
					Else
						NewRow.TextOwnerGiver = "";
					EndIf;
					
				EndIf;
				If Not TSName = "LaborCosts" Then
					NewRow.LineOfBusiness = GroupDetails.LineOfBusiness;
				EndIf;
				
			EndIf;
			
			If Not TSName = "LaborCosts" Then
				RowsToProcess.Add(NewRow);
			EndIf;
			
			RowsArray.Add(NewRow.GetID());
			
		EndDo;
		
		If TSName = "MaterialsAndWorks"
			Or TSName = "SideAndIntermediateRelease" Then
			
			StructureOfActions = New Structure;
			AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True, TSName = "MaterialsAndWorks");
			AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
			If TSName = "SideAndIntermediateRelease" Then
				InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
			EndIf;
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				ObjectTable,
				CachedValues);
			
			If TSName = "SideAndIntermediateRelease" Then
				For Each CurrentRow In RowsToProcess Do
					IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.SideAndIntermediateRelease");
				EndDo;
			EndIf;
			
		EndIf;
		
		If TSName = "MaterialsAndWorks"
			Or TSName = "SideAndIntermediateRelease"
			Or TSName = "LaborCosts" Then
			AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
		EndIf;
	
	EndIf;
	
EndProcedure

&AtServer
Procedure FillDefaultWarehouse()
	
	If UseSeveralWarehouses Then
		DefaultWarehouse = Catalogs.Warehouses.EmptyRef();
	Else
		DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	EndIf;
	
	DefaultWarehouseShopStoreroom =
		?(ValueIsFilled(DefaultWarehouse), ObjectAttributeValue(DefaultWarehouse, "ShopFloorStockroom"), False);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDefaultWarehouseInLine(Form, String, FieldName)
	
	If Form.UseSeveralWarehouses Then
		Return;
	EndIf; 
	
	String[FieldName] = Form.DefaultWarehouse;
	String.ShopFloorStockroom = Form.DefaultWarehouseShopStoreroom;
	String.MustBeRoundOff = Not String.ShopFloorStockroom;

EndProcedure

&AtClient
Procedure FillInTheWarehouse(TSName, FieldName)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng mà muốn điền kho.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить склад.';
							|en = 'Select the lines for which it is required to populate the warehouse.'; fa = 'Select the lines for which it is required to populate the warehouse.';
							|it = 'È necessario selezionare le righe per le quali deve essere compilato il magazzino.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić magazyn.';
							|tr = 'Ambarı doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TSName", TSName);
	AdditionalParameters.Insert("FieldName", FieldName);
	
	CallbackDescription = New CallbackDescription("FillInTheWarehouseCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("Catalog.Warehouses.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInTheWarehouseCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	FillWarehouseOnServer(ClosingResult, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure FillWarehouseOnServer(WarehouseValue, AdditionalParameters)
	
	TSName = AdditionalParameters.TSName;
	FieldName = AdditionalParameters.FieldName;
	
	StructureOfActions = New Structure;
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
	
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	RowsToProcess = New Array();
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		
		If (TSName = "ManufacturedProducts"	Or TSName = "SideAndIntermediateRelease")
		   And Not CurrentData.DirectionOfProductionIssue =
		   			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse") Then
			Continue;
		EndIf;
		
		CurrentData[FieldName] = WarehouseValue;
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		TabularSection,
		ValuesInCache);
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, SelectedRows);
	
EndProcedure

&AtClient
Procedure FillInCostDivision(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng mà muốn điền bộ phận chi phí.';
							|ru = 'Необходимо выбрать строки, для которых необходимо заполнить подразделение затрат.';
							|en = 'Select lines for which a cost business unit should be populated.'; fa = 'Select lines for which a cost business unit should be populated.';
							|it = 'È necessario selezionare le righe per le quali è necessario compilare il centro dei costi.';
							|pl = 'Należy wybrać wiersze, dla których trzeba wypełnić dział kosztów.';
							|tr = 'Gider departmanını doldurmanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInCostDivisionCompletion", ThisObject, TSName);
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure FillInCostDivisionCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		If TSName = "MaterialsAndWorks"
			And CurrentData.ShopFloorStockroom Then
			Continue;
		EndIf;
		CurrentData.Department = ClosingResult;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillInExpenseItem(TSName, FieldName)
	
	SelectedRows = New Array;
	For Each CurID_ In Items[TSName].SelectedRows Do
		
		CurrentData = Object[TSName].FindByID(CurID_);
		If CurrentData = Undefined Then
			Continue;
		EndIf;
		
		If CurrentData.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
			SelectedRows.Add(CurID_);
		EndIf;
		
	EndDo;
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject,
		Items[TSName + FieldName],
		SelectedRows);
	
EndProcedure

&AtClient
Procedure OpenCostShareEntryForm(CurrentData)

	NoErrors_ = ProductionClient.CheckFillingBeforeEnteringCostFraction(CurrentData, CostAllocationParameters);
	
	If NoErrors_ Then
		FormParameters = ParametersOfCostShareEntryForm_(CurrentData.GetID());
		OpenForm("CommonForm.EnterCostShare",
			FormParameters,
			ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessingInputOfFractionOfCost(Item, CurrentData, ValueSelected)
	
	If CurrentData.CostShare <> ValueSelected.CostShare Then
		
		ProductionClientServer.FillInCostFractionInLine(
			CurrentData,
			ValueSelected);
			
		Groups = New Array;
		Groups.Add(CurrentData.CostGroupNumber);
		CalculatePercentageOfCostAllocationForOutputProducts(Groups);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateIssueForActivities(Fill = True)
	
	FillParameters = Documents.BackflushProduction.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.ProductionIssueForActivity,
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	
	VATAccountingERP.FillInActivitySelectionList(
		Items.ProductionIssueForActivity,
		Object.ProductionIssueForActivity,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure OutputProductsFillInTheSpecificationServer(Val IDs = Undefined)
	
	ModifiedRows = FillInSpecificationInTablePart(IDs);
	
	If Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOM
		Or Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByProductBOMAndAssignments Then
		UpdateCostGroupsAfterChangingSpecifications(ModifiedRows);
	EndIf;
	
EndProcedure

&AtServer
Function FillInSpecificationInTablePart(Val IDs = Undefined, CheckFillMode = False)
	
	Modified = True;
	RowsArray = New Array;
	
	If IDs <> Undefined Then
		For Each Id In IDs Do
			String = Object.ManufacturedProducts.FindByID(Id);
			RowsArray.Add(String);
		EndDo;
	Else
		For Each String In Object.ManufacturedProducts Do
			RowsArray.Add(String);
		EndDo;
	EndIf;
	
	DataArray = New Array;
	
	For Each CurrentRow In RowsArray Do
		
		ProductData = ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
			Object, CurrentRow, BOMSelectionParameters);
		If CheckFillMode Then
			ProductData.Insert("CurrentSpecification", CurrentRow.BillOfMaterials);
		EndIf;
		ProductData.Insert("OldSpecification", CurrentRow.BillOfMaterials);
		
		DataArray.Add(ProductData);
		
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(RowsArray, DataArray, BOMSelectionParameters);
	
	ArrayOfModifiedStrings = New Array;
	For It = 0 To RowsArray.UBound() Do
		If RowsArray[It].BillOfMaterials <> DataArray[It].OldSpecification Then
			ArrayOfModifiedStrings.Add(RowsArray[It]);
		EndIf;
	EndDo;
	Return ArrayOfModifiedStrings;
	
EndFunction

&AtServer
Procedure AddOutputProductsAccordingToSpecificationServer(Val IDs)
	
	ItemList = Catalogs.BillsOfMaterials.ItemList();
	ItemList.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	For Each Id In IDs Do
		String = Object.ManufacturedProducts.FindByID(Id);
		
		If Not ValueIsFilled(String.BillOfMaterials) Then
			Continue;
		EndIf;
		
		NewRow = ItemList.Add();
		FillPropertyValues(NewRow, String);
		NewRow.ProductionStart = Object.Date;
	EndDo;
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters("ManufacturedProducts");
	SelectionParameters.OverridingReleasePartySetting.Use = True;
	SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
	SelectionParameters.CalculateShareOfCostOfOutputProducts = True;
	
	SpecificationsData = Catalogs.BillsOfMaterials.SpecificationDataByProductsList(ItemList, SelectionParameters);
	
	FilterParameters   = New Structure("BillOfMaterials,Products,Characteristic", );
	RowsArray       = New Array;
	RowsToProcess = New Array;
	For Each StructureOfData In SpecificationsData Do
		
		If Not StructureOfData.Property("ManufacturedProducts") Then
			Continue;
		EndIf;
		
		FilledWithAppointments = 0;
		CurAssignment = PredefinedValue("Catalog.Assignments.EmptyRef");
		For Each String In StructureOfData.ManufacturedProducts Do
			
			FillPropertyValues(FilterParameters, String);
			FilterParameters.BillOfMaterials = StructureOfData.BillOfMaterials;
			Product = ItemList.FindRows(FilterParameters);
			
			If Product.Count() > 0 Then
				CurAssignment = Product[0].Purpose;
				Continue;
			EndIf;
			
			FilledWithAppointments = ?(ValueIsFilled(CurAssignment),FilledWithAppointments + 1,FilledWithAppointments);
			
			NewRow = Object.ManufacturedProducts.Add();
			FillPropertyValues(NewRow, String);
			
			NewRow.Purpose = CurAssignment;
			NewRow.Count = String.ProductQuantity;
			NewRow.InternalSubcontracting = Object.InternalSubcontracting;
			NewRow.MaterialProviderCompany    = Object.MaterialProviderCompany;
			RowsArray.Add(NewRow.GetID());
			RowsToProcess.Add(NewRow);
			
		EndDo;
		
		If ValueIsFilled(CurAssignment) And FilledWithAppointments <> StructureOfData.ManufacturedProducts.Count() -1 Then
			LastBlank = Object.ManufacturedProducts.Count() - 1 - FilledWithAppointments;
			NumberOfUnfilled = StructureOfData.ManufacturedProducts.Count() - 1 - FilledWithAppointments;
			
			For N1 = LastBlank - NumberOfUnfilled + 1 To LastBlank Do
				Object.ManufacturedProducts[N1].Purpose = CurAssignment;
			EndDo;
			
		EndIf;
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingProducts("ManufacturedProducts", ThisObject, StructureOfActions, True, False);
	AddWarehouseActionsToStructure("ManufacturedProducts", ThisObject, StructureOfActions);
	AddShopPantryActionsToStructure("ManufacturedProducts", StructureOfActions, True, False);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.ManufacturedProducts,
		CachedValues);
	
	For Each CurrentRow In RowsToProcess Do
		IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, "Object.ManufacturedProducts");
		AddChangeCostGroup(CurrentRow);
	EndDo;
	
	AfterChangingTSStringsProgrammaticallyOnServer("ManufacturedProducts", RowsArray, StructureOfActions);
	
EndProcedure

&AtServer
Procedure UpdateCostGroupsAfterChangingSpecifications(Rows)
	
	If Not ValueIsFilled(Rows)
		Or Object.Patch
			And Object.CorrectionSavesProductionLots Then
		Return;
	EndIf;
	
	For Each CurrentData In Rows Do
		
		StringFields = "CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series";
		StringFields = "CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series, InternalSubcontracting, MaterialProviderCompany";
		CurDataStructure = New Structure(StringFields);
		
		FillPropertyValues(CurDataStructure, CurrentData);
		AddChangeCostGroup(CurDataStructure);
		
		CurrentData.CostGroupNumber = CurDataStructure.CostGroupNumber;
		CurrentData.ExpenseGroup = CurDataStructure.ExpenseGroup;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure EstablishUseOfPlannedValue()
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		Object.Organization,
		Object.Date);
	
	If Not AccountingPolicyParameters = Undefined Then
		UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenProductSelectionByOrders()
	
	HeaderAttributes = New Structure("Organization, Department, Ref, LineOfBusiness");
	FillPropertyValues(HeaderAttributes, Object);
	
	FormParameters = New Structure();
	FormParameters.Insert("HeaderAttributes",                           HeaderAttributes);
	FormParameters.Insert("OrderDocument",                                    Undefined);
	FormParameters.Insert("Invoice",                                Object.Ref);
	FormParameters.Insert("AdvancedWarehousingOnShipment",                 True);
	FormParameters.Insert("AddressGoods",                              AddressInvoiceGoods());
	FormParameters.Insert("InvoiceForOrders",                       False);
	FormParameters.Insert("UseInvoicesForSeveralOrders", False);
	FormParameters.Insert("OrdersAreUsed",                       False);
	
	OpenForm("CommonForm.AddItemsFromSalesOrderGoodsIssue",
		FormParameters, ThisForm, UUID,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Function AddressInvoiceGoods()
	
	Table = Object.MaterialsAndWorks.Unload();
	Return PutToTempStorage(Table);
	
EndFunction
#Region LineOfBusiness

// Returns the parameters required for filling in the activity direction
//
// Parameters:
//  Object - FormDataStructure - source for filling in parameters
//		
// Returns:
//  - Structure
//
&AtClientAtServerNoContext
Function ParametersAndDirectionOfActivity(Object)
	
	FillingParameters = New Structure;
	FillingParameters.Insert("LineOfBusiness");
	
	FillPropertyValues(FillingParameters, Object);
	
	Return FillingParameters;
	
EndFunction	

// Fills in the "activity Directions" in the table
//
// Parameters:
//  TSName     - String               - name of the table part to process
//  Var_Parameters - See ParametersAndDirectionOfActivity
//  Rows    - Array, Undefined - array of processed strings
//
&AtServer
Procedure FillInActivityDirectionInTable(TSName, Var_Parameters, Rows = Undefined)

	Table = Object[TSName];
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.LineOfBusiness AS LineOfBusiness,
	|	Table.Purpose AS Purpose
	|INTO Table
	|FROM
	|	&Table AS Table
	|
	|INDEX BY
	|	Purpose
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	ISNULL(Table.Purpose.LineOfBusiness, &LineOfBusiness) AS LineOfBusiness
	|FROM
	|	Table AS Table
	|WHERE
	|	Table.LineOfBusiness <> ISNULL(Table.Purpose.LineOfBusiness, &LineOfBusiness)";
	
	Query.SetParameter("Table", Table.Unload(Rows, "LineNumber, LineOfBusiness, Purpose"));
	Query.SetParameter("LineOfBusiness", Var_Parameters.LineOfBusiness);

	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		FillPropertyValues(Table[Selection.LineNumber - 1], Selection,, "LineNumber");
	EndDo;
	
EndProcedure

// Adds the "fill in activity Directions" action to the action structure
//
// Parameters:
//	StructureOfActions - Structure - structure of actions
//	Object - FormDataStructure - source for filling in parameters
//
&AtClient
Procedure AddActionFillActivityDirection(StructureOfActions, Object)
			
	StructureOfActions.Insert("FillInDirectionOfActivity", ParametersAndDirectionOfActivity(Object));
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersManufacturedProducts

&AtServer
Procedure OutputItemsBeforeDeletingOnServer()
	
	For Each CurID_ In Items.ManufacturedProducts.SelectedRows Do
		DeleteCostGroup(CurID_);
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndWorks

&AtServer
Procedure MaterialsAndWorksAfterDeletionOnServer()
	
	If RightToReadSubstitutes And ShowAnalogues Then
		NotePresenceOfAnalogues();
	EndIf;
	
	FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	
EndProcedure

#EndRegion

#Region FormServiceCommandHandlers

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties



&AtServer
Procedure DisplayInternalProcessingOnServer()
	
	DisplayGiversInCostGroup =
		DisplayInternalProcessingOfCurrentDocument
		Or Object.ManufacturedProducts.FindRows(New Structure("InternalSubcontracting", True)).Count() > 0;
	
	ConfigureCostGroupingElements(False);
	
EndProcedure
&AtClient
Procedure OpensGoodsSelection(TSName)
	
	If TSName = "MaterialsAndWorks" Then
		HeaderParameter_ = NStr("vi = 'Chọn nguyên vật liệu và công việc vào %1';
								|ru = 'Подбор материалов и работ в %1';
								|en = 'Pick materials and works in %1'; fa = 'Pick materials and works in %1';
								|it = 'Selezione materiali e lavori in %1';
								|pl = 'Wybór materiałów i prac w %1';
								|tr = '%1 içinde malzeme ve iş seçimi'");
	ElsIf TSName = "ManufacturedProducts" Or TSName = "SideAndIntermediateRelease" Then
		HeaderParameter_ = NStr("vi = 'Chọn sản phẩm vào %1';
								|ru = 'Подбор изделий в %1';
								|en = 'Pick finished products in %1'; fa = 'Pick finished products in %1';
								|it = 'Selezione articoli in %1';
								|pl = 'Wybór wyrobów w %1';
								|tr = '%1 içinde nihai ürün seçimi'");
	Else
		HeaderParameter_ = NStr("vi = 'Chọn vào %1';
								|ru = 'Подбор в %1';
								|en = 'Pick in %1'; fa = 'Pick in %1';
								|it = 'Selezione in %1';
								|pl = 'Wybór w %1';
								|tr = '%1 içinde seçim'");
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrTemplate(HeaderParameter_, Object.Ref);
	Else
		HeaderParameter_ = StrTemplate(HeaderParameter_, NStr("vi = 'sản xuất không có đơn hàng';
																|ru = 'производство без заказа';
																|en = 'backflush production'; fa = 'backflush production';
																|it = 'produzione senza ordine';
																|pl = 'produkcja bez zamówień';
																|tr = 'geriye dönük üretim'"));
	EndIf;
	
	ArrayOfProductTypes = New Array();
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	AvailableProductTypes = New FixedArray(ArrayOfProductTypes);
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectionModeWithoutAmountParameters", True);
	FormParameters.Insert("HideTheViewPriceColumn",            True);
	FormParameters.Insert("HideTheItemPricesCommand",   True);
	FormParameters.Insert("Title",               HeaderParameter_);
	FormParameters.Insert("Document",                Object.Ref);
	FormParameters.Insert("Date",                    Object.Date);
	FormParameters.Insert("FilterByProductType", AvailableProductTypes);
	FormParameters.Insert("AllWarehouseBalance",               True);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", True);
	
	Notification = New CallbackDescription("OpensGoodsSelectionCompletion",
		ThisObject,
		TSName);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
		FormParameters,
		ThisObject,
		UUID,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure OpensGoodsSelectionCompletion(ValueSelected, TSName) Export
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	StartProcessingSelectionResultOnServer(ValueSelected.GoodsAddressInStorage, "SelectGoods", TSName);
	
EndProcedure

&AtServer
Procedure StartProcessingSelectionResultOnServer(GoodsAddressInStorage, SelectionOption, TSName = "MaterialsAndWorks")
	
	TableOfGoods = GetFromTempStorage(GoodsAddressInStorage); // ValueTable
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;

	ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName);
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(TableOfGoods, TSName)
	
	RowsToProcess = New Array;
	ProductData_2 = New Array;
	RowsArray = New Array;
	For Each String In TableOfGoods Do
		
		NewRow = ObjectTableByName(Object, TSName).Add();
		FillPropertyValues(NewRow, String);
		
		RowsToProcess.Add(NewRow);
		
		If TSName = "ManufacturedProducts" Then
			ProductData_2.Add(
				ProductDataManagementClientServer.CollectProductDataForSpecificationSelection(
					Object, NewRow, BOMSelectionParameters, ThisObject));
		EndIf;
		
		RowsArray.Add(NewRow.GetID());
		
	EndDo;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True, TSName = "MaterialsAndWorks");
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
	EndIf;
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTableByName(Object, TSName),
		CachedValues);
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		
		If TSName = "ManufacturedProducts" Then
			KTCHPath = "Object.ManufacturedProducts";
		Else
			KTCHPath = "Object.SideAndIntermediateRelease";
		EndIf;
		
		If TSName = "ManufacturedProducts" Then
			ProductDataManagement.FillInSpecificationInLines(RowsToProcess, ProductData_2, BOMSelectionParameters);
		EndIf;
		
		For Each CurrentRow In RowsToProcess Do
			CurrentRow.InternalSubcontracting = Object.InternalSubcontracting;
			CurrentRow.MaterialProviderCompany    = Object.MaterialProviderCompany;
			IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentRow, KTCHPath);
			
			If TSName = "ManufacturedProducts" Then
				AddChangeCostGroup(CurrentRow);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);

EndProcedure

&AtClient
Procedure GetDataFromTSD(TSName)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject, New Structure("TSName", TSName)),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(AdditionalParameters.TSName, Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(TSName)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject, New Structure("TSName", TSName));
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(Result, AdditionalParameters) Export
	
	NameOfTCHPOISKByBarcode = AdditionalParameters.TSName;
	
	ProcessBarcodes(AdditionalParameters.TSName, Result);
	
EndProcedure

&AtClient
Procedure GetWeight(TSName)
	
	ClearMessages();
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm, TSName);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, New Structure("CurrentRow,TSName",
																						CurrentRow, TSName)),
		UUID);
	
EndProcedure

// Parameters:
// 	ExecutionResult - Structure - Result
// 	AdditionalParameters - Structure - LongDesc:
// * CurrentRow - FormDataCollectionItem - Current line
&AtClient
Procedure GetWeightCompletion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		AdditionalParameters.CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		
		AddActionsToStructureWhenChangingPackagesNumber(
			AdditionalParameters.TSName,
			ThisForm,
			StructureOfActions);
		
		BatchProcessingOfTablePartClient.ProcessTSString(AdditionalParameters.CurrentRow,
														StructureOfActions,
														CachedValues);
		
		If AdditionalParameters.TSName = "ManufacturedProducts"
			Or AdditionalParameters.TSName = "SideAndIntermediateRelease"
			Or AdditionalParameters.TSName = "MaterialsAndWorks" Then
			
			IDCurrentRow = AdditionalParameters.CurrentRow.GetID();
			
			UpdateCachedValuesToAccountForSeries(
				AdditionalParameters.TSName,
				Items[AdditionalParameters.TSName],
				CachedValues,
				False);
			
			FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
				SeriesSpecificationParameters[AdditionalParameters.TSName],
				IDCurrentRow,
				CachedValues);
			
		EndIf; 
		
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(TSName, BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActionsWithAddedStrings,, TSName = "MaterialsAndWorks");
	AddWarehouseActionsToStructure(TSName, ThisObject, StructureOfActionsWithAddedStrings);
	AddShopPantryActionsToStructure(TSName, StructureOfActionsWithAddedStrings, True, TSName = "MaterialsAndWorks");
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisObject, StructureOfActionsWithAddedStrings);
	
	If TSName = "MaterialsAndWorks" Then
		AddSeriesActionsToStructure(StructureOfActionsWithAddedStrings, Undefined, SeriesSpecificationParameters[TSName]);
	EndIf;
	If TSName = "SideAndIntermediateRelease" Then
		InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActionsWithAddedStrings);
	EndIf;
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisObject, StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.TSName                                  = TSName;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters[TSName];
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		If TSName = "ManufacturedProducts" Then
			AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_ManufacturedProducts", 0.1, True);
		ElsIf TSName = "SideAndIntermediateRelease" Then
			AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_SideAndIntermediateRelease", 0.1, True);
		Else
			AttachIdleHandler("Attachable_OpenSeriesSelectionWhenScanningProductBarCode_MaterialsAndWorks", 0.1, True);
		EndIf;
	EndIf;
	
	If StructureOfActions.CurrentRow <> Undefined Then
		FormData1 = Items[TSName]; // FormTable
		FormData1.CurrentRow = StructureOfActions.CurrentRow;
	EndIf;
	
	CalculatePercentageOfCostAllocationForOutputProducts();
	
	If TSName = "ManufacturedProducts"
		Or TSName = "SideAndIntermediateRelease" Then
		
		SetProductGroupHeaders(ThisObject, TSName);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject,
															Object,
															StructureOfActionParameters,
															CachedValues);
	
	If StructureOfActionParameters.TSName = "MaterialsAndWorks"
		And StructureOfActionParameters.CurrentRow <> Undefined Then
		
		If RightToReadSubstitutes And ShowAnalogues Then
			NotePresenceOfAnalogues();
		EndIf;
		
	EndIf;
	
	If StructureOfActionParameters.TSName = "MaterialsAndWorks" Then
		FormEvents.WhenChangingElement(ThisObject, "RawMaterials");
	ElsIf StructureOfActionParameters.TSName = "ManufacturedProducts" Then
		For Each CurrentData In Object.ManufacturedProducts Do
			If Not ValueIsFilled(CurrentData.CostGroupNumber) Then
				AddChangeCostGroup(CurrentData);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure BreakTSString(TSName)
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.AllowZeroCount = False;
	
	If TSName = "LaborCosts" Then
		StringSplittingParameters.FieldNameQuantity = "Count";
	EndIf;
	
	Notification = New CallbackDescription("BreakTSStringCompletion", ThisObject, TSName);
	ProcessingOfTabularFormsClient.SplitRow(Object[TSName], Items[TSName], Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure BreakTSStringCompletion(NewRow, TSName) Export 
	
	If NewRow = Undefined Then
		Return;
	EndIf;
	
	If TSName = "ManufacturedProducts"
		Or TSName = "LaborCosts" Then
		NewRow.RowCode = 0;
	EndIf;
	
	CurrentData = Items[TSName].CurrentData;
	
	If Not TSName = "LaborCosts" Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(
				TSName,
				ThisForm,
				StructureOfActions);
		If TSName = "SideAndIntermediateRelease" Then
			InternalSubcontractingClientServer.AddActionFillInItemOwnerIsAvailable(ThisObject, StructureOfActions);
		EndIf;
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		If TSName = "ManufacturedProducts" Then
			NewRow.InternalSubcontracting = Object.InternalSubcontracting;
			NewRow.MaterialProviderCompany    = Object.MaterialProviderCompany;
			If Not Object.Patch
				Or Not Object.CorrectionSavesProductionLots Then
				
				NewLineStructure =
					New Structure("CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series");
				NewLineStructure =
					New Structure("CostGroupNumber, ExpenseGroup, Products, Characteristic, BillOfMaterials, Purpose, Series, InternalSubcontracting, MaterialProviderCompany");
				FillPropertyValues(NewLineStructure, NewRow);
				AddChangeCostGroup(NewLineStructure);
				
				NewRow.CostGroupNumber = NewLineStructure.CostGroupNumber;
				NewRow.ExpenseGroup = NewLineStructure.ExpenseGroup;
				
			EndIf;
			
			ProductionClientServer.RecalculateFractionOfCostWhenSplittingRow(NewRow, CurrentData, CostAllocationParameters.MethodOfAllocatingFinishedProductCosts);
			
		EndIf;
		
	EndIf;
	
	RowsArray = New Array;
	RowsArray.Add(CurrentData.GetID());
	RowsArray.Add(NewRow.GetID());
	
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

&AtClient
Procedure RoundToTheWholePackage(TSName)
	
	ClearMessages();
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		WarningText = NStr("vi = 'Cần chọn các hàng muốn làm tròn số lượng.';
							|ru = 'Необходимо выбрать строки, для которых необходимо округлить количество.';
							|en = 'Select the lines for which the quantity should be rounded off.'; fa = 'Select the lines for which the quantity should be rounded off.';
							|it = 'È necessario selezionare le righe per le quali è necessario arrotondare la quantità.';
							|pl = 'Należy wybrać wiersze, dla których trzeba zaokrąglić ilość';
							|tr = 'Miktarı yuvarlamanız gereken satırları seçmeniz gerekmektedir.'");
		CommonClient.MessageToUser(WarningText);
		Return;
	EndIf;
	
	TotalRows = 0;
	For Each RowID In SelectedRows Do
		RowData = Object[TSName].FindByID(RowID);
		If Int(RowData.NumberOfPackages) = RowData.NumberOfPackages Then
			Continue;
		EndIf;
		TotalRows = TotalRows + 1;
	EndDo;
	
	If TotalRows = 0 Then
		ShowUserNotification(
			NStr("vi = 'Không cần làm tròn';
				|ru = 'Округление не требуется';
				|en = 'Rounding is not required'; fa = 'Rounding is not required';
				|it = 'L''arrotondamento non è richiesto';
				|pl = 'Zaokrąglenie nie jest potrzebne';
				|tr = 'Yuvarlama gerekmemektedir'"),, 
			NStr("vi = 'Các hàng được chọn đã có số nguyên đơn vị.';
				|ru = 'В выбранных строках уже целое количество единиц.';
				|en = 'There is already a whole number of units in the selected lines.'; fa = 'There is already a whole number of units in the selected lines.';
				|it = 'Nelle righe selezionate è già presente un numero intero di unità.';
				|pl = 'W wybranych wierszach już jest liczba całkowita jednostek.';
				|tr = 'Seçili satırlarda zaten tam sayı birimi mevcut.'"),
			PictureLib.Information32);
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các dòng đã chọn, số lượng sẽ được làm tròn đến hàng đơn vị. 
							|Tiếp tục?';
							|ru = 'В выбранных строках количество будет округлено до целых единиц. 
							|Продолжить?';
							|en = 'The selected lines will be rounded up to integral units.
							|Continue?'; fa = 'The selected lines will be rounded up to integral units.
							|Continue?';
							|it = 'Nelle righe selezionate, la quantità verrà arrotondata a unità intere. 
							|Continuare?';
							|pl = 'W wybranych wierszach ilość zostanie zaokrągloną do liczb całkowitych. 
							|Kontynuować?';
							|tr = 'Seçili satırlardaki miktar, tam sayı birimlerine yuvarlanacaktır. 
							|Devam edilsin mi?'");
							
	CallbackDescription = New CallbackDescription("RoundToTheWholePackageCompletion",
													ThisObject,
													New Structure("TSName", TSName));
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continuare';
												|pl = 'Continue';
												|tr = 'Devam et'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList); 
	
EndProcedure

&AtClient
Procedure RoundToTheWholePackageCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	RoundUpToWholePackageOnServer(AdditionalParameters.TSName, CachedValues);
	NotificationText1 = NStr("vi = 'Các hàng được chọn được làm tròn cho toàn bộ đơn vị.';
							|ru = 'В выбранных строках выполнено округление до целых единиц.';
							|en = 'The selected lines are rounded up to integral units.'; fa = 'The selected lines are rounded up to integral units.';
							|it = 'Nelle righe selezionate è eseguito arrotondamento a intere unità.';
							|pl = 'W wybranych wierszach wykonano zaokrąglenie do liczb całkowitych.';
							|tr = 'Seçilen satırlarda tam sayı birimlerine yuvarlama gerçekleşti.'");
	ShowUserNotification(NStr("vi = 'Hoàn thành làm tròn';
								|ru = 'Выполнено округление';
								|en = 'Rounded'; fa = 'گردشده';
								|it = 'Eseguito arrotondamento';
								|pl = 'Wykonano zaokrąglenie';
								|tr = 'Yuvarlama gerçekleşti'"),, NotificationText1, PictureLib.Success32);
	
EndProcedure

&AtServer
Procedure RoundUpToWholePackageOnServer(TSName, CachedValues)
	
	StructureOfActions = New Structure;
	ArrayOfDimensions = New Array;
	AddActionsToStructureWhenChangingPackagesNumber(TSName, ThisObject, StructureOfActions);
	RowsToProcess = New Array();
	
	For Each RowID In Items[TSName].SelectedRows Do
		RowData = Object[TSName].FindByID(RowID);
		If Int(RowData.NumberOfPackages) = RowData.NumberOfPackages Then
			Continue;
		EndIf;
		RowData.NumberOfPackages = Int(RowData.NumberOfPackages) + 1;
		
		RowsToProcess.Add(RowData);
		
		If TSName = "ManufacturedProducts" Then
			ArrayOfDimensions.Add(RowData.CostGroupNumber);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object[TSName],
		CachedValues);
	
	If TSName = "ManufacturedProducts" Then
		CalculatePercentageOfCostAllocationForOutputProducts(ArrayOfDimensions);
	EndIf;
	
	FillInStatusesForSpecifyingSeriesServer(TSName);
	
EndProcedure

&AtServer
Procedure LaborCostsAreDeterminedWhenChangingOnServer()
	
	CurrentData = Object.LaborCosts.FindByID(Items.LaborCosts.CurrentRow);
	
	FillInTypeOfContractor(CommonClientServer.ValueInArray(CurrentData));
	
EndProcedure

&AtServer
Procedure FillInDefaultSubdivisionInCollection(RowsArray)
	
	For Each String In RowsArray Do
		If Not ValueIsFilled(String.Department) Then
			String.Department = Object.Department;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure FillInTypeOfContractor(Collection)
	
	Departments = Object.LaborCosts.Unload(Collection).UnloadColumn("Department");
	
	Attributes = Common.ObjectsAttributesValues(Departments,
															"UseTeamWorkOrders,UsePersonalWorkOrders");
	
	For Each String In Collection Do
		
		If ValueIsFilled(String.Department)
			And Not Attributes[String.Department].UseTeamWorkOrders
			And TypeOf(String.Performer) = Type("CatalogRef.Teams") Then
			String.Performer = Catalogs.Persons.EmptyRef();
		ElsIf ValueIsFilled(String.Department)
			And Not Attributes[String.Department].UsePersonalWorkOrders
			And (TypeOf(String.Performer) = Type("CatalogRef.Persons")
			) Then
			String.Performer = Catalogs.Teams.EmptyRef();
		EndIf;
		
		If String.Performer = Undefined Then
			String.Performer = Catalogs.Teams.EmptyRef();
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure PerformerGettingSelectionData(ChoiceData, Text, Parameters)
	
	ChoiceData = New ValueList;
	ProductionServer.FillInSelectionDataWhenEnteringArtist(ChoiceData, Text, Parameters);
	
EndProcedure

&AtServer
Procedure ProductSelectionProcessing(AddressInStorage)
	
	CalculationResult1 = GetFromTempStorage(AddressInStorage);
	Table = CalculationResult1.Goods; // TabularSection
	
	FieldsNames = "LineNumber";
	TSName = "MaterialsAndWorks";
	TheStructureOfTheSearch = New Structure(FieldsNames);
	Table.Sort(FieldsNames + " Desc");
	
	// Grouping a table by row keys.
	StringTree = New Array();
	For Each TableRow In Table Do
		
		If TheStructureOfTheSearch.LineNumber <> TableRow.LineNumber Then
			
			RowsArray = New Array();
			StringTree.Add(RowsArray);
			
			FillPropertyValues(TheStructureOfTheSearch, TableRow);
			
		EndIf;
		
		RowsArray.Add(TableRow);
		
	EndDo;
	
	AddedRows = New Array();
	TheStructureOfTheSearch = New Structure(FieldsNames);
	For Each SelectedLines_ In StringTree Do
		
		FillPropertyValues(TheStructureOfTheSearch, SelectedLines_[0]);
		FoundRows = Object[TSName].FindRows(TheStructureOfTheSearch);
		
		// New row - adding rows.
		If FoundRows.Count() = 0 Then
			
			For Each SourceRow In SelectedLines_ Do
				
				If SourceRow.Count > 0 Then
					DestinationRow = Object[TSName].Add();
					FillPropertyValues(DestinationRow, SourceRow);
					AddedRows.Add(DestinationRow);
				EndIf;
				
			EndDo;
			
		Else
			
			If FoundRows.Count() > 1 Then
				
				For Counter = 1 To FoundRows.Count() - 1 Do
					Object[TSName].Delete(FoundRows[Counter]);
				EndDo;
				
			EndIf;
			
			If SelectedLines_.Count() = 1 Then
			
				SourceRow = SelectedLines_[0];
				DestinationRow = FoundRows[0];
				If SourceRow.Count = 0 Then
					Object[TSName].Delete(DestinationRow);
				Else
					FillPropertyValues(DestinationRow, SourceRow);
				EndIf;
			
			Else
				
				DestinationRow = FoundRows[0];
				DestinationRow.Count = 0;
				
				For Each SourceRow In SelectedLines_ Do
				
					If SourceRow.Count > 0 Then
						FillPropertyValues(DestinationRow, SourceRow);
						DestinationRow = Object[TSName].Add();
						AddedRows.Add(DestinationRow);
					EndIf;
				
				EndDo;
				
				If DestinationRow.Count = 0 Then
					Object[TSName].Delete(DestinationRow);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	RowsArray = New Array;
	StructureOfActions = Undefined;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(TSName, ThisObject, StructureOfActions, True, True);
	AddShopPantryActionsToStructure(TSName, StructureOfActions, True, TSName = "MaterialsAndWorks");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActions,
		Object[TSName],
		CachedValues);

	For Each CurrentRow In AddedRows Do
		RowsArray.Add(CurrentRow.GetID());
	EndDo;
	
	SalesServerLocalization.TransferBarcodesOfPackages(ThisObject, CalculationResult1.PackageBarcodes, "PackagingUnitBarcodesMaterials");
	AfterChangingTSStringsProgrammaticallyOnServer(TSName, RowsArray, StructureOfActions);
	
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function ObjectAttributeValue(Object, AttributeName)
	
	Return Common.ObjectAttributeValue(Object, AttributeName);
	
EndFunction

&AtClientAtServerNoContext
Function ObjectTableByName(Object, TSName)
	
	If TSName = "ManufacturedProducts" Then
		ObjectTable = Object.ManufacturedProducts;
	ElsIf TSName = "SideAndIntermediateRelease" Then
		ObjectTable = Object.SideAndIntermediateRelease;
	ElsIf TSName = "MaterialsAndWorks" Then
		ObjectTable = Object.MaterialsAndWorks;
	ElsIf TSName = "LaborCosts" Then
		ObjectTable = Object.LaborCosts;
	Else
		ObjectTable = Undefined;
	EndIf;
	
	Return ObjectTable;
	
EndFunction

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
