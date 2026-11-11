
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Parameters.Property("State",         FilterState);
	Parameters.Property("RegistrationPeriod", Period);
	
	FiltersStructure = Undefined;
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		QuickFilterStructure = New Structure;
		
		If FiltersStructure.Property("Organization", FilterOrganization) Then
			QuickFilterStructure.Insert("Organization", FilterOrganization);
		EndIf;
		
		If FiltersStructure.Property("Department", FilterDepartment) Then
			QuickFilterStructure.Insert("Department", FilterDepartment);
		EndIf;
		
	Else
		Parameters.Property("QuickFilterStructure", QuickFilterStructure);
		If QuickFilterStructure = Undefined Then
			Parameters.Property("Organization",	FilterOrganization);
			Parameters.Property("Department",	FilterDepartment);
		Else
			QuickFilterStructure.Property("Organization", FilterOrganization);
			QuickFilterStructure.Property("Department", FilterDepartment);
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	If Parameters.Property("ArrangeProductionWithoutOrders") Then
		Items.ProductionWithoutOrdersGroup.Visible = Parameters.ArrangeProductionWithoutOrders;
	Else
		Items.ProductionWithoutOrdersGroup.Visible = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	RefreshStatus();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ProductionCostAllocation" Then
		
		CurrentData = Items.UsedMaterials.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		
		If Not Parameter = Undefined
			And CurrentData.Ref = Parameter.Ref Then
			FillPropertyValues(CurrentData, Parameter, "Existence, Allocate, Allocated, Ref");
			Details = ProductionClientServer.DecryptingIncomingBalance(CurrentData);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("FilterOrganization");
		Settings.Delete("FilterDepartment");
	Else
		If Parameters.Property("Department") Then
			Settings["FilterDepartment"] = Parameters.Department;
		EndIf;
		If Parameters.Property("Organization") Then
			Settings["FilterOrganization"] = Parameters.Organization;
		EndIf;
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		Settings["Period"] = Parameters.RegistrationPeriod;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillInMaterials();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Period, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	EndIf;
	
	ClearMessages();
	FillInMaterials();
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction,
		StandardProcessing,
		Period,
		MonthLine);
	
	ClearMessages();
	FillInMaterials();
	
EndProcedure

&AtClient
Procedure MonthLineClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	ClearMessages();
	FillInMaterials();
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	ClearMessages();
	FillInMaterials();
EndProcedure

&AtClient
Procedure FilterItemsTypeOnChange(Item)
	ClearMessages();
	FillInMaterials();
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	RefreshStatus();
EndProcedure

&AtClient
Procedure RefreshStatus()
	
	If FilterState = "Allocated" Then
		Items.UsedMaterials.RowFilter = New FixedStructure("AllocationIsRequired", False);
	ElsIf FilterState = "AllocationIsRequired" Then
		Items.UsedMaterials.RowFilter = New FixedStructure("AllocationIsRequired", True);
	Else
		Items.UsedMaterials.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkProductionDocumentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.OpenLog(LogParameters());
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure CostsSelection(Item, RowSelected, Field, StandardProcessing)
	
	DecryptTheField(Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure UsedMaterialsOnActivateRow(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	Details = ProductionClientServer.DecryptingIncomingBalance(CurrentData);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure UsedMaterialsExistenceOnChange(Item)
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData = Undefined Then
		Return
	EndIf;
	
	If CurrentData.Existence > CurrentData.IncomingBalance Then
		CurrentData.Existence = CurrentData.IncomingBalance;
		MessageText = NStr("vi = 'Lượng sẵn có thực tế của vật liệu trong kho tại xưởng không thể vượt quá số dư đến.';
							|ru = 'Фактическое наличие материала в кладовой не может превышать входящий остаток.';
							|en = 'Actual material availability in the storeroom cannot exceed the incoming balance.'; fa = 'Actual material availability in the storeroom cannot exceed the incoming balance.';
							|it = 'Presenza fisica di materiale nel magazzino non può superare giacenze in entrata.';
							|pl = 'Faktyczna dostępność materiału w magazynie nie może przekroczyć bilansu wejściowego.';
							|tr = 'Ambardaki gerçek malzeme mevcudiyeti, gelen bakiyeyi aşamaz.'");
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
	CurrentData.Allocate = CurrentData.IncomingBalance - CurrentData.Existence - CurrentData.Allocated;
	
	StructureOfData = DocumentStructure();
	FillPropertyValues(StructureOfData, CurrentData);
	StructureOfData.Date = EndOfMonth(Period);
	
	DocumentRef = WriteToDistributionInDocument(StructureOfData);
	
	If DocumentRef <> Undefined Then
		CurrentData.Ref = DocumentRef;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenDistributionDocumentCommand(Command)
	
	OpenAllocationDocument();

EndProcedure

&AtClient
Procedure TheDecryptFieldCommand(Command)
	
	CurItemCosts = Items.UsedMaterials.CurrentItem;
	If CurItemCosts = Undefined Then
		Return;
	EndIf;
	
	If Not DecryptTheField(CurItemCosts.Name) Then
		ShowMessageBox(, NStr("vi = 'Giải mã của trường đã chọn không được cung cấp.';
								|ru = 'Расшифровка выбранного поля не предусмотрена.';
								|en = 'Drill-down of the selected field is not supported.'; fa = 'Drill-down of the selected field is not supported.';
								|it = 'Decodifica del campo selezionato non è prevista.';
								|pl = 'Szczegóły dla wybranego pola nie są dostępne.';
								|tr = 'Seçili alanın detaylandırılması ön görülmedi.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure TheTeamOpenTheMovementOfMaterialsProductsWorks(Command)
	
	Filter = New Structure;
	
	If ValueIsFilled(FilterOrganization) Then
		Filter.Insert("Organization", FilterOrganization);
		
	EndIf;
	
	If ValueIsFilled(FilterDepartment) Then
		Filter.Insert("Department", FilterDepartment);
	EndIf;
	
	If ValueIsFilled(FilterItemsType) Then
		Filter.Insert("ItemsType", FilterItemsType);
	EndIf;
	
	OpenTheMovementOfMaterialsProductsWorks(Filter);
	
EndProcedure

&AtClient
Procedure PrintInventoryReportCommand(Command)
	
	ParameterOrganization = PredefinedValue("Catalog.Companies.EmptyRef");
	If Items.UsedMaterials.CurrentData <> Undefined Then
		ParameterOrganization = Items.UsedMaterials.CurrentData.Organization;
	ElsIf ValueIsFilled(FilterOrganization) Then
		ParameterOrganization = FilterOrganization;
	EndIf;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("Organization",       ParameterOrganization);
	PrintParameters.Insert("Department",     FilterDepartment);
	PrintParameters.Insert("Period",            Period);
	PrintParameters.Insert("NewProduction", True);
	AddExpensesParameter(PrintParameters);
	
	PrintManagementClient.ExecutePrintCommand(
		"Document.ProductionCostAllocation", 
		"ActOfInventoryOfMaterialsAndSemiFinishedProducts", 
		ParameterOrganization, 
		Undefined, 
		PrintParameters);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	ClearMessages();
	FillInMaterials();
	
EndProcedure

&AtClient
Procedure ArrangeProductionWithoutOrders(Command)
	FormParameters = New Structure("RegistrationPeriod, Organization", Period, FilterOrganization);
	OpenForm("DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm", FormParameters, ThisForm);
	Return; // in UT, KA empty
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#Region CreateCommandHandlers

&AtClient
Procedure CreateInternalAcceptanceNote(Command)
	CreateDocumentBasedOn("InternalAcceptanceCertificate");
EndProcedure

&AtClient
Procedure CreateAcceptanceNote(Command)
	CreateDocumentBasedOn("CustomerInvoiceServices");
EndProcedure

&AtClient
Procedure CreateReturnOfMaterialsFromStoreroom(Command)
	CreateDocumentBasedOn("ReturnOfMaterialsFromStoreroom");
EndProcedure

&AtClient
Procedure CreateTransferOfProductsFromThePantry(Command)
	CreateDocumentBasedOn("TransferOfProductsFromStoreroom");
EndProcedure

&AtClient
Procedure CreateAMoveOfSemiFinishedProducts(Command)
	CreateDocumentBasedOn("TransferOfSemiFinishedProducts");
EndProcedure

&AtClient
Procedure CreateSalesOfGoodsAndServices(Command)
	CreateDocumentBasedOn("SalesOfGoodsAndServices");
EndProcedure

#EndRegion

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.UsedMaterials);
EndProcedure
&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.UsedMaterials, Result);
EndProcedure
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.UsedMaterials);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region FillingForm

&AtServer
Procedure FillInMaterials()
	
	DateOfMigrationToBatchAccounting22 = CalculationOfCostCached.DateOfMigrationToBatchAccounting22();
	
	If ValueIsFilled(DateOfMigrationToBatchAccounting22) And DateOfMigrationToBatchAccounting22 > BegOfMonth(Period) Then
		
		UsedMaterials.Clear();
		
		ErrorText = NStr("vi = 'Trong kỳ đã định có sử dụng kế toán theo lô phiên bản 2.1.
		|Để phân bổ nguyên vật liệu và công việc, cần sử dụng chỗ làm việc tương tự dành cho phiên bản 2.1. Chỗ làm việc khả dụng trong nhóm ""Xem thêm"" thuộc phân hệ Sản xuất.';
		|ru = 'В указанном периоде используется партионный учет версии 2.1.
		|Для распределения материалов и работ рекомендуется воспользоваться аналогичным рабочим местом для версии 2.1. Рабочее место доступно в группе ""См. также"" раздела Производство.';
		|en = 'Lot accounting 2.1 is used in the specified period.
		|It is recommended that you use the workplace with version 2.1 to allocate materials and works. You can access the workplace from the ""See also"" group of the Production section.'; fa = 'Lot accounting 2.1 is used in the specified period.
		|It is recommended that you use the workplace with version 2.1 to allocate materials and works. You can access the workplace from the ""See also"" group of the Production section.';
		|it = 'Nel periodo indicato si usa la versione 2.1 di contabilità per lotti.
		|Per la distribuzione dei materiali e lavori si consiglia di utilizzare la postazione di lavoro analoga per la versione 2.1. La postazione di lavoro è disponibile nel gruppo ""Vedi anche"" della sezione Produzione.';
		|pl = 'W podanym okresie używana jest ewidencji partii wersji 2.1.
		|Dla przydziału materiałów i robót zalecane jest użycie analogicznego miejsca pracy dla wersji 2.1. Miejsce pracy jest dostępne w grupie ""Zobacz także"" w dziale Produkcja.';
		|tr = 'Belirtilen dönemde lot muhasebesi 2.1. sürümü kullanılmaktadır.
		|Malzeme ve iş dağıtımı için, 2.1. sürümün ilişkin benzer çalışma alanının kullanılması önerilmektedir. Çalışma alanı, Üretim bölümünün ""Ayrıca bk."" grubunda mevcuttur.'");
		
		Common.MessageToUser(ErrorText);
		
		Return;
		
	EndIf;

	BorderEndDate = New Boundary(EndOfMonth(Period), BoundaryType.Including);
	Query = New Query(Documents.ProductionCostAllocation.RequestTextForMaterialsAndWorksInStorerooms());
	Query.TempTablesManager = New TempTablesManager;
	
	AvailableCompanies = AvailableCompanies(FilterOrganization);
	
	Query.SetParameter("AllRegisteredRecords",              True);
	Query.SetParameter("BeginOfPeriod",            BegOfMonth(Period));
	Query.SetParameter("BorderEndOfPeriod_",  BorderEndDate);
	Query.SetParameter("PeriodEnding",         EndOfMonth(Period));
	Query.SetParameter("AllCompanies",           AvailableCompanies.Count() = 0);
	Query.SetParameter("Companies",              AvailableCompanies);
	Query.SetParameter("AllDepartments",         Not ValueIsFilled(FilterDepartment));
	Query.SetParameter("Departments",            CommonClientServer.ValueInArray(FilterDepartment));
	Query.SetParameter("AllTypesOfProducts",      Not ValueIsFilled(FilterItemsType));
	Query.SetParameter("ItemsType",          FilterItemsType);
	Query.SetParameter("AllAnalysts",	           True);
	Query.SetParameter("ItemsLocationAttributes",Undefined);
	
	SetPrivilegedMode(True);
	
	CostTable = Query.Execute().Unload();
	CostTable.Sort("Organization, Department, Warehouse, Products, Characteristic, Series");
	
	UsedMaterials.Load(CostTable);
	
EndProcedure

&AtServer
Function AvailableCompanies(Organization = Undefined)
	
	CompaniesList = New ValueList;
	If Not ValueIsFilled(Organization) Then
		Query = New Query("
		|SELECT ALLOWED
		|	CatalogData.Ref AS Organization
		|FROM
		|	Catalog.Companies AS CatalogData
		|WHERE
		|	(CatalogData.Ref = &Organization
		|	OR &Organization = VALUE(Catalog.Companies.EmptyRef) OR &Organization = UNDEFINED)
		|	AND
		|	(CatalogData.Ref <> VALUE(Catalog.Companies.ManagementCompany))
		|");
		Query.SetParameter("Organization", Organization);
		CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
		CompaniesList.LoadValues(CompanyArray);
	Else
		CompaniesList.Add(Organization);
	EndIf;
	Return CompaniesList;
	
EndFunction

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function DocumentStructure()
	
	DocumentStructure = New Structure("NewProduction, Date, Organization, Department, ItemsLocationAttributes,
	|Warehouse, Products, Characteristic, Series, BatchesIndicationStatus, Purpose, Ref, Allocate");
	
	DocumentStructure.NewProduction = True;
	
	Return DocumentStructure;
	
EndFunction

&AtClient
Procedure OpenAllocationDocument()
	
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Ref.IsEmpty() Then
		BaseStructure = DocumentStructure();
		BaseStructure.Date = EndOfMonth(Period);
		FillPropertyValues(BaseStructure, CurrentData);
		FormParameters = New Structure("Basis", BaseStructure);
	ElsIf Not CurrentData.NewProduction Then
		Text = NStr("vi = 'Đã thực hiện phân bổ bởi chứng từ để sản xuất phiên bản 2.1. Để làm việc với chứng từ, cần chuyển đến chỗ làm việc phân bổ 2.1.
			|Để phân bổ sản xuất phiên bản 2.2 cần đặt dấu xóa chứng từ phân bổ hiện tại.';
			|ru = 'Распределение выполнено документом для производства версии 2.1. Для работы с документом требуется перейти в рабочее место распределения 2.1.
			|Для распределения на производство версии 2.2 существующий документ распределения следует пометить на удаление.';
			|en = 'Allocation is performed by a production document version 2.1. To work with the document, go to the allocation workplace 2.1. 
			|To allocate to production of version 2.2, mark the existent allocation document for deletion.'; fa = 'Allocation is performed by a production document version 2.1. To work with the document, go to the allocation workplace 2.1. 
			|To allocate to production of version 2.2, mark the existent allocation document for deletion.';
			|it = 'Distribuzione eseguita con il documento per la produzione in versione 2.1. Per lavorare con il documento è necessario passare alla postazione di lavoro di distribuzione 2.1.
			| Per la distribuzione in produzione in versione 2.2 il documento di distribuzione esistente deve essere contrassegnato per l''eliminazione.';
			|pl = 'Przydział wykonano przez dokument do produkcji wersji 2.1. Aby pracować z dokumentem musisz przejść do miejsca pracy przydziału 2.1.
			|W celu przydziału do produkcji wersji 2.2 istniejący dokument przydziału powinien zostać oznaczony do usunięcia.';
			|tr = 'Dağıtım, üretim sürümü 2.1. için belge tarafından gerçekleştirildi. Belgeyle çalışmak için dağıtım 2.1. çalışma alanına gitmeniz gerekmektedir.
			|Üretim sürümü 2.2''ye dağıtmak için mevcut dağıtım belgesinin silinmek üzere işaretlenmesi gerekmektedir.'");
		ShowMessageBox(, Text);
		Return;
	Else
		FormParameters = New Structure("Key", CurrentData.Ref);
	EndIf;
	
	FormParameters.Insert("IncomingBalance",  CurrentData.IncomingBalance);
	FormParameters.Insert("OpeningBalance", CurrentData.OpeningBalance);
	FormParameters.Insert("Received",        CurrentData.Received);
	FormParameters.Insert("Passed",         CurrentData.Passed);
	
	OpenForm("Document.ProductionCostAllocation.ObjectForm", FormParameters, Items.UsedMaterials);
	
EndProcedure

&AtServer
Function WriteToDistributionInDocument(StructureOfData)
	
	If ValueIsFilled(StructureOfData.Ref) Then
		
		DocumentObject = StructureOfData.Ref.GetObject();
		DocumentObject.Allocate = StructureOfData.Allocate;
		
	Else
		
		DocumentObject = Documents.ProductionCostAllocation.CreateDocument();
		DocumentObject.Fill(StructureOfData);
		
	EndIf;
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
		Return DocumentObject.Ref;
	Except
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return Undefined;
	EndTry;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False, "UsedMaterialsSeries", "UsedMaterials.BatchesIndicationStatus", "UsedMaterials.ItemsType");

	// the organization is not displayed if selection is enabled

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsOrganization.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterOrganization");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Catalogs.Companies.EmptyRef();

	Item.Appearance.SetParameterValue("Visible", False);

	// the division is not displayed if selection is enabled

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Catalogs.BusinessStructure.EmptyRef();

	Item.Appearance.SetParameterValue("Visible", False);
	
	// the storeroom is not displayed if job selection is enabled

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FilterItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	Item.Appearance.SetParameterValue("Visible", False);

	// the quantity to be distributed is highlighted in red

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsAllocate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.Allocate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

	// if distribution is not required

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsAllocate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.Allocate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "UsedMaterialsCharacteristic",
																		     "UsedMaterials.ItemVariantsAreUsed");

	// without an appointment if the appointment is not filled.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsedMaterialsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<without assignment>'; fa = '<بدون تخصیص>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// the storeroom is not specified for work

	ProductTypeWork = New ValueList;
	ProductTypeWork.LoadValues(ProductsClientServer.JobSelection(False));
	
	ConditionalDesignParameters = WarehousesServer.ParametersOfConditionalAppearanceOfVHFWarehouseByItemType();
	ConditionalDesignParameters.Form = ThisObject;
	ConditionalDesignParameters.NameOfWarehouseInputField = Items.UsedMaterialsWarehouse.Name;
	ConditionalDesignParameters.NameOfItemTypeField = "UsedMaterials.ItemsType";
	ConditionalDesignParameters.TypeOfComparisonOfItemTypes = DataCompositionComparisonType.InList;
	ConditionalDesignParameters.ItemsTypes = ProductTypeWork;
	ConditionalDesignParameters.TextColor = StyleColors.InaccessibleCellTextColor;
	
	WarehousesServer.SetConditionalAppearanceOfVHFWarehouseByTypeOfItem(ConditionalDesignParameters);

EndProcedure

&AtClient
Function DecryptTheField(FieldName, StandardProcessing = False)
	
	If FieldName = "UsedMaterialsAllocate" Or FieldName = "UsedMaterialsAllocated" Then
		
		StandardProcessing = False;
		OpenAllocationDocument();
	ElsIf FieldName = "UsedMaterialsBalance" Then
		
		StandardProcessing = False;
		
		CurrentData = Items.UsedMaterials.CurrentData;
		
		If CurrentData = Undefined Then
			Return True;
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("Products",       CurrentData.Products);
		Filter.Insert("Characteristic",     CurrentData.Characteristic);
		Filter.Insert("WarehouseDivision", ?(ValueIsFilled(CurrentData.Warehouse), CurrentData.Warehouse, CurrentData.Department));
		Filter.Insert("Series",              CurrentData.Series);
		Filter.Insert("Purpose",         CurrentData.Purpose);
		Filter.Insert("Organization",        CurrentData.Organization);
		
		OpenTheMovementOfMaterialsProductsWorks(Filter);
		
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure OpenTheMovementOfMaterialsProductsWorks(Filter)
	
	UserParameters = New Array;
	StandardPeriod = New StandardPeriod;
	StandardPeriod.StartDate = BegOfMonth(Period);
	StandardPeriod.EndDate = EndOfMonth(Period);
	CustomSetting = New Structure("Name, Value", "Period", StandardPeriod);
	UserParameters.Add(CustomSetting);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter",                     Filter);
	FormParameters.Insert("UserParameters", UserParameters);
	FormParameters.Insert("VariantKey",              "MovementOfMaterialsProductsWorks");
	FormParameters.Insert("GenerateOnOpen",   True);
	OpenForm("Report.ProductionMaterialCost.Form", FormParameters, ThisForm, True);
	
EndProcedure

&AtClient
Procedure CreateDocumentBasedOn(Type)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"Document.ProductionCostAllocation.Form.MaterialAndLaborAllocationForm.CreateDocumentBasedOn");
	// End StandardSubsystems.PerformanceMeasurement
	
	RowsArray = Items.UsedMaterials.SelectedRows;
	
	If RowsArray = Undefined Then
		Return;
	EndIf;
	
	HeaderAttributes = New Structure("Organization, Department, Storeroom");
	Goods = New Array;
	
	HasErrors					= False;
	ThereAreMistakesOrganization		= False;
	ThereAreErrorsDivision		= False;
	ThereIsAlsoPantry			= False;
	ThereAreErrorsTypeProducts	= False;
	ThereAreErrorsNoData			= False;
	ThereIsOneDesignOption	= False;
	
	CurOrganization = Undefined;
	CurDivision = Undefined;
	CurPantry = Undefined;
	
	For Each CurRow In RowsArray Do
		CurrentData = UsedMaterials.FindByID(CurRow);
		
		If CurOrganization = Undefined Then
			CurOrganization = CurrentData.Organization;
			CurDivision = CurrentData.Department;
			CurPantry = CurrentData.Warehouse;
			
			FillPropertyValues(HeaderAttributes, CurrentData);
			
			If Type = "ReturnOfMaterialsFromStoreroom"
				Or Type = "TransferOfProductsFromStoreroom"
				Or Type = "TransferOfSemiFinishedProducts" Then
				
				HeaderAttributes.Insert("Sender", CurrentData.Warehouse);
				
				If Type = "ReturnOfMaterialsFromStoreroom" Then
					HeaderAttributes.Insert("BusinessOperation",
						PredefinedValue("Enum.BusinessTransactions.ReturnOfMaterialsFromStoreroom"));
				EndIf;
				
				If Type = "TransferOfProductsFromStoreroom" Then
					HeaderAttributes.Insert("BusinessOperation",
						PredefinedValue("Enum.BusinessTransactions.TransferOfProductsFromStoreroom"));
				EndIf;
				
				If Type = "TransferOfSemiFinishedProducts" Then
					HeaderAttributes.Insert("BusinessOperation",
						PredefinedValue("Enum.BusinessTransactions.TransferOfSemiFinishedProducts"));
				EndIf;
				
			EndIf;
			
			If Type = "SalesOfGoodsAndServices" Then
				HeaderAttributes.Insert("Warehouse", CurrentData.Warehouse);
			EndIf;
				
		EndIf;
		
		If Not CurOrganization = CurrentData.Organization Then
			HasErrors = True;
			ThereAreMistakesOrganization = True;
		EndIf;
		
		If Not CurDivision = CurrentData.Department Then
			HasErrors = True;
			ThereAreErrorsDivision = True;
		EndIf;
		
		If Not CurPantry = CurrentData.Warehouse Then
			HasErrors = True;
			ThereIsAlsoPantry = True;
		EndIf;
		
		If (Type = "InternalAcceptanceCertificate"
				Or Type = "CustomerInvoiceServices")
			And Not CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			HasErrors = True;
			ThereAreErrorsTypeProducts = True;
		EndIf;
		
		If (Type = "ReturnOfMaterialsFromStoreroom"
				Or Type = "TransferOfProductsFromStoreroom"
				Or Type = "TransferOfSemiFinishedProducts")
			And CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
			HasErrors = True;
			ThereAreErrorsTypeProducts = True;
		EndIf;
		
		If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
			And Type = "CustomerInvoiceServices"
			And Not CurrentData.SaleRegistrationOption = PredefinedValue("Enum.SalesRegistrationOptions.CustomerInvoiceServices") Then
			HasErrors = True;
			ThereIsOneDesignOption = True;
		EndIf;
		
		If CurrentData.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
			And Type = "SalesOfGoodsAndServices"
			And Not CurrentData.SaleRegistrationOption = PredefinedValue("Enum.SalesRegistrationOptions.CustomerInvoice") Then
			HasErrors = True;
			ThereIsOneDesignOption = True;
		EndIf;
		
		If CurrentData.Existence > 0 Then
			ProductStructure_2 = New Structure("Products, ItemsType, Characteristic,
											|Series, Purpose, ProductFullName,
											|CharacteristicFullName, Count, NumberOfPackages");
			FillPropertyValues(ProductStructure_2, CurrentData);
			ProductStructure_2.Count			= CurrentData.Existence;
			ProductStructure_2.NumberOfPackages	= CurrentData.Existence;
			Goods.Add(ProductStructure_2);
		EndIf;
		
	EndDo;
	
	If Goods.Count() = 0 Then
		HasErrors = True;
		ThereAreErrorsNoData = True;
	EndIf;
	
	If HasErrors Then
		If ThereAreErrorsNoData Then
			ErrorText = NStr("vi = 'Không có hàng yêu cầu phân bổ.';
							|ru = 'Отсутствуют строки, требующие распределения.';
							|en = 'No lines that require allocation.'; fa = 'No lines that require allocation.';
							|it = 'Mancano le righe che necessitano di distribuzione.';
							|pl = 'Brak wierszy wymagających przydziału.';
							|tr = 'Dağıtılması gereken satırlar bulunmamaktadır.'");
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;
		
		If ThereAreMistakesOrganization
				Or ThereAreErrorsDivision
				Or ThereIsAlsoPantry Then
			ErrorText = NStr("vi = 'Trong các dòng được chọn, các giá trị khác nhau:';
							|ru = 'В выбранных строках различаются значения:';
							|en = 'Values are different in the selected lines:'; fa = 'Values are different in the selected lines:';
							|it = 'Nelle righe selezionate i valori sono diversi:';
							|pl = 'Wybrane wiersze mają różne znaczenia:';
							|tr = 'Seçili satırlardaki değerler farklıdır:'");
			
			If ThereAreMistakesOrganization Then
				ErrorText = ErrorText + Chars.LF + Chars.Tab +  NStr("vi = '- Doanh nghiệp';
																	|ru = '- Организаций';
																	|en = '- Companies'; fa = '- Companies';
																	|it = '- Delle organizzazioni';
																	|pl = '- Firmy';
																	|tr = '- İş yerleri'");
			EndIf;
			
			If ThereAreErrorsDivision Then
				ErrorText = ErrorText + Chars.LF + Chars.Tab + NStr("vi = '- Bộ phận';
																	|ru = '- Подразделений';
																	|en = '- Business units'; fa = '- Business units';
																	|it = '- Di reparti';
																	|pl = '- Działów';
																	|tr = '- Departmanlar'");
			EndIf;
			
			If ThereIsAlsoPantry Then
				ErrorText = ErrorText + Chars.LF + Chars.Tab + NStr("vi = '- Kho bãi';
																	|ru = '- Кладовых';
																	|en = '- Storerooms'; fa = '- Storerooms';
																	|it = '- Di magazzini';
																	|pl = '- Magazyn';
																	|tr = '- Ambarların'");
			EndIf;
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;
		
		If ThereAreErrorsTypeProducts Then
			ErrorText = NStr("vi = 'Chứng từ này không nhằm phản ánh các chuyển động trong mục đã chọn.';
							|ru = 'Документ не предназначен для отражения движений по выбранной номенклатуре.';
							|en = 'Document is not designed for recording movements for the selected items.'; fa = 'Document is not designed for recording movements for the selected items.';
							|it = 'Documento non predisposto alla visualizzazione di movimenti dell''articolo scelto.';
							|pl = 'Dokument nie jest przeznaczony do odzwierciedlenia przepływów w wybranym wykazie towarów.';
							|tr = 'Belge, seçili öğeye göre hareketlerin yansıtılması için tasarlanmamıştır.'");
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;
		
		If ThereIsOneDesignOption Then
			ErrorText = NStr("vi = 'Trong các dòng được chọn, tùy chọn đăng ký bán một mặt hàng không tương ứng với loại chứng từ được vẽ lên.';
							|ru = 'В выбранных строках вариант оформления продажи номенклатуры не соответствует типу оформляемого документа.';
							|en = 'Sale registration option of items in the selected lines does not correspond to the registered document type.'; fa = 'Sale registration option of items in the selected lines does not correspond to the registered document type.';
							|it = 'Nelle righe selezionate l''opzione di formalizzazione della vendita dell''articolo non corrisponde al tipo di documento che viene registrato.';
							|pl = 'W wybranych wierszach wariant sporządzenia sprzedaży towarów nie odpowiada typu dokumentu, który ma zostać sporządzony.';
							|tr = 'Seçili satırlarda, öğe satışını düzenleme seçeneği, düzenlenecek belge türüyle eşleşmemektedir.'");
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;
		
		ErrorText = NStr("vi = 'Không thể lập chứng từ!';
						|ru = 'Оформление документа невозможно!';
						|en = 'Cannot register the document.'; fa = 'Cannot register the document.';
						|it = 'La registrazione del documento è impossibile!';
						|pl = 'Sporządzenie dokumentu nie jest możliwe';
						|tr = 'Belgenin düzenlenmesi mümkün değildir!'");
		CommonClientServer.MessageToUser(ErrorText);
		Return;
	Else
		BasisParameters = New Structure;
		BasisParameters.Insert("HeaderAttributes", HeaderAttributes);
		If Type = "CustomerInvoiceServices" Then
			BasisParameters.Insert("Services", Goods);
		Else
			BasisParameters.Insert("Goods", Goods);
		EndIf;
	EndIf;
	
	OpeningParameters = New Structure("Basis", BasisParameters);
	
	If Type = "InternalAcceptanceCertificate" Then
		NameOfDocumentForm = "Document.InternalAcceptanceCertificate.ObjectForm";
	ElsIf Type = "CustomerInvoiceServices" Then
		NameOfDocumentForm = "Document.CustomerInvoiceServices.ObjectForm";
	ElsIf Type = "ReturnOfMaterialsFromStoreroom"
			Or Type = "TransferOfProductsFromStoreroom"
			Or Type = "TransferOfSemiFinishedProducts" Then
		NameOfDocumentForm = "Document.MovementOfProductsAndMaterials.ObjectForm";
	ElsIf Type = "SalesOfGoodsAndServices" Then
		NameOfDocumentForm = "Document.CustomerInvoice.ObjectForm";
	EndIf;
	
	OpenForm(NameOfDocumentForm, OpeningParameters, ThisForm);
	
EndProcedure

&AtServer
Function LogParameters()
	
	LogParameters = New Structure;
	LogParameters.Insert("FormAssignmentKey", "MaterialsAndWorksCostAllocation");
	LogParameters.Insert("WorkplaceName", "LogOfProductionDocuments");
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ sản xuất';
												|ru = 'Документы производства';
												|en = 'Production documents'; fa = 'اسناد تولید';
												|it = 'Documenti di produzione';
												|pl = 'Dokumenty produkcji';
												|tr = 'Üretim belgeleri'"));
	ListFormSelections = New Structure;
	ListFormSelections.Insert("Period", New StandardPeriod(BegOfMonth(Period), EndOfMonth(Period)));
	ListFormSelections.Insert("Organization", FilterOrganization);
	ListFormSelections.Insert("Department", FilterDepartment);
	
	FilterDocumentTypes = New ValueList;
	
	FilterDocumentTypes.Add(Common.MetadataObjectID("Document.ProductionCostAllocation"));
	ListFormSelections.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	FilterBusinessTransactions = New ValueList;
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.ExpensingToProductionLots);
	ListFormSelections.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	
	LogParameters.Insert("ListFormSelections", ListFormSelections);
	
	Return LogParameters;
	
EndFunction

&AtServer
Procedure AddExpensesParameter(PrintParameters)

	PrintParameters.Insert("Costs", 
		PutToTempStorage(UsedMaterials.Unload(), New UUID()));

EndProcedure

#EndRegion

#EndRegion
