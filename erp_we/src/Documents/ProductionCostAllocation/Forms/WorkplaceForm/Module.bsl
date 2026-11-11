
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("State", State);
	Parameters.Property("Organization", Organization);
	Parameters.Property("RegistrationPeriod", Period);
	
	If Parameters.Property("YouNeedToWriteOffCosts") Then
		Items.GroupWriteOffOfOutputCosts.Visible = Parameters.YouNeedToWriteOffCosts;
	Else
		Items.GroupWriteOffOfOutputCosts.Visible = False;
	EndIf;
	If Not ValueIsFilled(Period) Then
		Period = CurrentSessionDate();
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	Items.CostsCharacteristic.Visible = GetFunctionalOption("UseItemVariants");
	Items.StandardKACosts.Visible = GetFunctionalOption("ComplexAutomation");
	Items.CostsOrganization.Visible = GetFunctionalOption("UseMultipleCompanies");
	Items.CostsProductionCosts.Visible = Not Items.StandardKACosts.Visible;
	
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
		
		CurrentRow = Items.Costs.CurrentData;
		If CurrentRow = Undefined Then
			Return
		EndIf;
		
		FillPropertyValues(CurrentRow, Parameter);
		
		CurrentRow.IsInProcessing = CurrentRow.OpeningBalance + CurrentRow.Received
				- CurrentRow.NormativeStandard
				- CurrentRow.Deviation
				- CurrentRow.WrittenOffAsExpenses
				- CurrentRow.Implemented
				- CurrentRow.Passed
				- CurrentRow.AllocatedToProduction
				- CurrentRow.RealBalance;
		
		CostsWhenChangingRow(CurrentRow);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("Organization") Then
		Settings["Organization"] = Parameters.Organization;
	EndIf;
	If Parameters.Property("Department") Then
		Settings["Department"] = Parameters.Department;
	EndIf;
	If Parameters.Property("RegistrationPeriod") Then
		Settings["Period"] = Parameters.RegistrationPeriod;
	EndIf;
	Settings["Organization"] = SettingsValueCached.GetDefaultOrganization(Settings["Organization"]);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillIn_Costs();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	TMCommonUseClient.StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, Period, ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	EndIf;
	FillIn_Costs();
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	Period = AddMonth(Period, Direction);
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	FillIn_Costs();
	
EndProcedure

&AtClient
Procedure MonthLineClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	FillIn_Costs();
	
EndProcedure

&AtClient
Procedure DepartmentClearing(Item, StandardProcessing)
	
	Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	FillIn_Costs();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	FillIn_Costs();
	
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	
	RefreshStatus();
	
EndProcedure

&AtClient
Procedure RefreshStatus()
	
	If State = "Allocated" Then
		Items.Costs.RowFilter = New FixedStructure("State", True);
	ElsIf State = "AllocationIsRequired" Then
		Items.Costs.RowFilter = New FixedStructure("State", False);
	Else
		Items.Costs.RowFilter = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCosts

&AtClient
Procedure CostsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure CostsSelection(Item, RowSelected, Field, StandardProcessing)
	
	DecryptTheField(Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure CostsRealBalanceOnChange(Item)
	
	CurrentData = Items.Costs.CurrentData;
	
	If ValueIsFilled(CurrentData.Document) And CurrentData.NewProduction Then
		Text = NStr("vi = 'Đã thực hiện phân bổ bởi chứng từ để sản xuất phiên bản 2.2. Để làm việc với chứng từ, cần chuyển đến chỗ làm việc phân bổ 2.2.
			|Để phân bổ sản xuất phiên bản 2.1 cần đặt dấu xóa chứng từ phân bổ hiện tại.';
			|ru = 'Распределение выполнено документом для производства версии 2.2. Для работы с документом требуется перейти в рабочее место распределения 2.2.
			|Для распределения на производство версии 2.1 существующий документ распределения следует пометить на удаление.';
			|en = 'Allocation is performed by a production document version 2.2. To work with the document, go to the allocation workplace 2.2. 
			|To allocate to production of version 2.1, mark the existent allocation document for deletion.'; fa = 'Allocation is performed by a production document version 2.2. To work with the document, go to the allocation workplace 2.2. 
			|To allocate to production of version 2.1, mark the existent allocation document for deletion.';
			|it = 'Distribuzione eseguita con il documento per la produzione in versione 2.2. Per lavorare con il documento è necessario passare alla postazione di lavoro della distribuzione 2.2.
			| Per la distribuzione in produzione in versione 2.1 il documento di distribuzione esistente deve essere contrassegnato per l''eliminazione.';
			|pl = 'Przydział wykonano przez dokument do produkcji wersji 2.2. Aby pracować z dokumentem, musisz przejść do miejsca pracy pracy 2.2.
			|W celu przydział do produkcji wersji 2.1 istniejący dokument przydziału powinien zostać oznaczony do usunięcia.';
			|tr = 'Dağıtım, üretim sürümü 2.2. için belge tarafından gerçekleştirildi. Belgeyle çalışmak için dağıtım 2.2. çalışma alanına gitmeniz gerekmektedir.
			|Üretim sürümü 2.1''e dağıtmak için mevcut dağıtım belgesinin silinmek üzere işaretlenmesi gerekmektedir.'");
		ShowMessageBox(, Text);
		CurrentData.RealBalance = 0;
		Return;
	EndIf;
	
	CostsSaveFactBalance(CurrentData);
	CostsWhenChangingRow(CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInTheActualBalanceOfTheAccountingAccount(Command)
	
	FillInTheActualBalanceOfTheAccountingAccountServer();
	
EndProcedure

&AtClient
Procedure OpenDistributionDocumentCommand(Command)
	
	OpenAllocationDocument();

EndProcedure

&AtClient
Procedure TheDecryptFieldCommand(Command)
	
	CurItemCosts = Items.Costs.CurrentItem;
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
Procedure TeamReportMaterialMovementInProduction(Command)
	Return; // WE have an empty handler
EndProcedure

&AtClient
Procedure PrintInventoryReportCommand(Command)
	
	ParameterOrganization = PredefinedValue("Catalog.Companies.EmptyRef");
	If Items.Costs.CurrentData <> Undefined Then
		ParameterOrganization = Items.Costs.CurrentData.Organization;
	ElsIf ValueIsFilled(Organization) Then
		ParameterOrganization = Organization;
	EndIf;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("Organization", ParameterOrganization);
	PrintParameters.Insert("Department", Department);
	PrintParameters.Insert("Period", Period);
	PrintParameters.Insert("Costs", Costs);
	
	PrintManagementClient.ExecutePrintCommand(
		"Document.ProductionCostAllocation", 
		"ActOfInventoryOfMaterialsAndSemiFinishedProducts", 
		ParameterOrganization, 
		Undefined, 
		PrintParameters);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	FillIn_Costs();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ProcessingTheFormSNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	ProductionCostAllocationClientLocalization.ProcessingTheFormSNavigationLink(
		Item,
		FormattedStringURL,
		StandardProcessing,
		ThisForm);
		
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.Costs);
EndProcedure
&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.Costs, Result);
EndProcedure
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.Costs);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region FillingForm

&AtServer
Procedure FillIn_Costs()
	
	Query = New Query;
	Query.Text = Documents.ProductionCostAllocation.RequestTextFillInProductionCosts();
	Query.SetParameter("BeginOfPeriod",		BegOfMonth(Period));
	BorderEndDate = New Boundary(EndOfMonth(Period), BoundaryType.Including);
	Query.SetParameter("BorderEndOfPeriod_", BorderEndDate);
	Query.SetParameter("PeriodEnding",	EndOfMonth(Period));
	Query.SetParameter("Organization", AvailableCompanies(Organization));
	Query.SetParameter("AllDepartments",	?(ValueIsFilled(Department), False, True));
	UnitParameter_ = New Array;
	UnitParameter_.Add(Department);
	Query.SetParameter("Departments",	UnitParameter_);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	CostTable = Result.Unload();
	CostTable.Sort("Organization, Department, Products, Characteristic, Series");
	Costs.Load(CostTable);
	Items.CostsOrganization.Visible = Not ValueIsFilled(Organization) And GetFunctionalOption("UseMultipleCompanies");;
	
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
		|");
		Query.SetParameter("Organization", Organization);
		CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
		CompaniesList.LoadValues(CompanyArray);
	Else
		CompaniesList.Add(Organization);
	EndIf;
	Return CompaniesList;
	
EndFunction

&AtServer
Procedure FillInTheActualBalanceOfTheAccountingAccountServer()
	
	SelectedRows = Items.Costs.SelectedRows;
	
	For Each String In SelectedRows Do
		
		RowData = Costs.FindByID(String);
		
		RowData.RealBalance = RowData.IsInProcessing;
		StructureOfData = New Structure();
		StructureOfData.Insert("Organization",        RowData.Organization);
		StructureOfData.Insert("Products",        RowData.Products);
		StructureOfData.Insert("Characteristic",      RowData.Characteristic);
		StructureOfData.Insert("Purpose",          RowData.Purpose);
		StructureOfData.Insert("Series",               RowData.Series);
		StructureOfData.Insert("Department",       RowData.Department);
		StructureOfData.Insert("CountReal",      RowData.RealBalance);
		StructureOfData.Insert("Document",            RowData.Document);
		SaveFactToDocument(StructureOfData);
		
		RowData.NotAllocated = RowData.OpeningBalance + RowData.Received
			- RowData.NormativeStandard
			- RowData.Deviation
			- RowData.WrittenOffAsExpenses
			- RowData.Passed
			- RowData.Implemented
			- RowData.AllocatedToProduction
			- RowData.RealBalance;
		
		RowData.IsInProcessing = RowData.NotAllocated;
		
		If RowData.NotAllocated > 0 Then
			RowData.ForAllocation = RowData.NotAllocated
			- Min(RowData.NotAllocated, RowData.LimitInProcessing);
		Else
			RowData.ForAllocation = RowData.NotAllocated;
		EndIf;
		
		If RowData.ForAllocation = 0 Then
			RowData.State = True
		Else
			RowData.State = False
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure OpenAllocationDocument()
	
	CurrentData = Items.Costs.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.Document.IsEmpty() Then
		BaseStructure = New Structure;
		BaseStructure.Insert("Date",               EndOfMonth(Period));
		BaseStructure.Insert("Organization",        CurrentData.Organization);
		BaseStructure.Insert("Department",      CurrentData.Department);
		BaseStructure.Insert("Products",       CurrentData.Products);
		BaseStructure.Insert("Characteristic",     CurrentData.Characteristic);
		BaseStructure.Insert("Series",              CurrentData.Series);
		BaseStructure.Insert("Purpose",         CurrentData.Purpose);
		BaseStructure.Insert("CountReal",     CurrentData.RealBalance);
		FormParameters = New Structure("Basis",     BaseStructure);
	ElsIf CurrentData.NewProduction Then
		Text = NStr("vi = 'Đã thực hiện phân bổ bởi chứng từ để sản xuất phiên bản 2.2. Để làm việc với chứng từ, cần chuyển đến chỗ làm việc phân bổ 2.2.
			|Để phân bổ sản xuất phiên bản 2.1 cần đặt dấu xóa chứng từ phân bổ hiện tại.';
			|ru = 'Распределение выполнено документом для производства версии 2.2. Для работы с документом требуется перейти в рабочее место распределения 2.2.
			|Для распределения на производство версии 2.1 существующий документ распределения следует пометить на удаление.';
			|en = 'Allocation is performed by a production document version 2.2. To work with the document, go to the allocation workplace 2.2. 
			|To allocate to production of version 2.1, mark the existent allocation document for deletion.'; fa = 'Allocation is performed by a production document version 2.2. To work with the document, go to the allocation workplace 2.2. 
			|To allocate to production of version 2.1, mark the existent allocation document for deletion.';
			|it = 'Distribuzione eseguita con il documento per la produzione in versione 2.2. Per lavorare con il documento è necessario passare alla postazione di lavoro della distribuzione 2.2.
			| Per la distribuzione in produzione in versione 2.1 il documento di distribuzione esistente deve essere contrassegnato per l''eliminazione.';
			|pl = 'Przydział wykonano przez dokument do produkcji wersji 2.2. Aby pracować z dokumentem, musisz przejść do miejsca pracy pracy 2.2.
			|W celu przydział do produkcji wersji 2.1 istniejący dokument przydziału powinien zostać oznaczony do usunięcia.';
			|tr = 'Dağıtım, üretim sürümü 2.2. için belge tarafından gerçekleştirildi. Belgeyle çalışmak için dağıtım 2.2. çalışma alanına gitmeniz gerekmektedir.
			|Üretim sürümü 2.1''e dağıtmak için mevcut dağıtım belgesinin silinmek üzere işaretlenmesi gerekmektedir.'");
		ShowMessageBox(, Text);
		Return;
	Else
		FormParameters = New Structure("Key", CurrentData.Document);
	EndIf;
	
	FormParameters.Insert("LimitInProcessing",   CurrentData.LimitInProcessing);
	FormParameters.Insert("Accounting_0Balance",  CurrentData.OpeningBalance
														+ CurrentData.Received
														- CurrentData.NormativeStandard
														- CurrentData.Deviation
														- CurrentData.Implemented
														- CurrentData.Passed);
	
	OpenForm("Document.ProductionCostAllocation.ObjectForm", FormParameters, Items.Costs);
	
EndProcedure

&AtServer
Function SaveFactToDocument(StructureOfData)
	
	If ValueIsFilled(StructureOfData.Document) Then
		DocumentObject = StructureOfData.Document.GetObject();
	Else
		DocumentObject = CreateNewDocument(StructureOfData);
	EndIf;
	DocumentObject.CountReal 		= StructureOfData.CountReal;
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
Function CreateNewDocument(AttributesStructure1)
	
	DocumentObject = Documents.ProductionCostAllocation.CreateDocument();
	DocumentObject.Date				= EndOfMonth(Period); 
	DocumentObject.EmployeeResponsible    = Users.CurrentUser();
	FillPropertyValues(DocumentObject, 
									AttributesStructure1,
									"Organization, Products, Characteristic, Series, Department, Purpose");
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(DocumentObject, Documents.ProductionCostAllocation);
	ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
	
	Return DocumentObject;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False, "CostsSeries", "Costs.BatchesIndicationStatus", "Costs.ItemsType");
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsDepartment.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Catalogs.BusinessStructure.EmptyRef();

	Item.Appearance.SetParameterValue("Visible", False);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "CostsCharacteristic",
																		     "Costs.ItemVariantsAreUsed");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsForAllocation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Costs.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsForAllocation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Costs.State");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsImplemented.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Costs.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.Work_5;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<dành cho công việc>';
													|ru = '<для работ>';
													|en = '<for works>'; fa = '<for works>';
													|it = '<per i lavori>';
													|pl = '<dla robót>';
													|tr = '<iş için>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

	// without an appointment if the appointment is not filled.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CostsPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Costs.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<without assignment>'; fa = '<بدون تخصیص>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

&AtClient
Procedure CostsWhenChangingRow(CurrentRow)
	
	If CurrentRow = Undefined Then
		Return
	EndIf;
	
	CurrentRow.NotAllocated = CurrentRow.OpeningBalance + CurrentRow.Received
				- CurrentRow.NormativeStandard
				- CurrentRow.Deviation
				- CurrentRow.WrittenOffAsExpenses
				- CurrentRow.Passed
				- CurrentRow.Implemented
				- CurrentRow.AllocatedToProduction
				- CurrentRow.RealBalance;
				
	CurrentRow.IsInProcessing = CurrentRow.NotAllocated;
	
	If CurrentRow.NotAllocated > 0 Then
		CurrentRow.ForAllocation = CurrentRow.NotAllocated
		- Min(CurrentRow.NotAllocated, CurrentRow.LimitInProcessing);
	Else
		CurrentRow.ForAllocation = CurrentRow.NotAllocated;
	EndIf;
		
	If CurrentRow.ForAllocation = 0 Then
		CurrentRow.State = True
	Else
		CurrentRow.State = False
	EndIf;
	
EndProcedure

&AtClient
Procedure CostsSaveFactBalance(CurrentRow)
	
	If CurrentRow = Undefined Then
		Return
	EndIf;
	StructureOfData = New Structure();
	StructureOfData.Insert("Organization",			CurrentRow.Organization);
	StructureOfData.Insert("Products",		CurrentRow.Products);
	StructureOfData.Insert("Characteristic",		CurrentRow.Characteristic);
	StructureOfData.Insert("Series",				CurrentRow.Series);
	StructureOfData.Insert("Department",		CurrentRow.Department);
	StructureOfData.Insert("CountReal",		CurrentRow.RealBalance);
	StructureOfData.Insert("Document",			CurrentRow.Document);
	StructureOfData.Insert("Purpose",			CurrentRow.Purpose);
	DocumentRef = SaveFactToDocument(StructureOfData);
	If DocumentRef <> Undefined Then
		CurrentRow.Document = DocumentRef;
	EndIf;

EndProcedure

&AtClient
Function DecryptTheField(FieldName, StandardProcessing = False)

	If FieldName = "CostsForAllocation" Then
		
		StandardProcessing = False;
		DecipheringRequirementsForDistribution();
		
	ElsIf FieldName = "CostsAllocatedToProduction" Then
		
		StandardProcessing = False;
		DecodingCostsAllocatedToProduction();
		
	ElsIf FieldName = "CostsWrittenOffAsExpenses" Then
		
		StandardProcessing = False;
		DecryptionCostsWrittenOffAsExpenses();
		
	Else
		
		ProductionCostAllocationClientLocalization.DecryptTheField(ThisObject, FieldName, StandardProcessing);
		
	EndIf; 

	Return True;
	
EndFunction

&AtClient
Procedure DecipheringRequirementsForDistribution()

	OpenAllocationDocument();

EndProcedure

&AtClient
Procedure DecodingCostsAllocatedToProduction()

	OpenAllocationDocument();

EndProcedure

&AtClient
Procedure DecryptionCostsWrittenOffAsExpenses()

	OpenAllocationDocument();

EndProcedure


#EndRegion

#EndRegion
