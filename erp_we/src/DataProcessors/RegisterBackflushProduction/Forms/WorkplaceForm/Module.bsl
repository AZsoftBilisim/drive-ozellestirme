#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	MultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	OnlyViewingCostGenerationModel =
		Not AccessRight("Update", Metadata.InformationRegisters.CostGenerationModels);
	
	FiltersStructure = Undefined;
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		QuickFilterStructure = New Structure;
		
		If FiltersStructure.Property("Organization", Organization) Then
			QuickFilterStructure.Insert("Organization", Organization);
		EndIf;
		If FiltersStructure.Property("Department", Department) Then
			QuickFilterStructure.Insert("Department", Department);
		EndIf;
	Else
		Parameters.Property("QuickFilterStructure", QuickFilterStructure);
		If QuickFilterStructure = Undefined Then
			If Not MultipleCompanies Then
				Organization = Undefined;
			Else
				Parameters.Property("Organization", Organization);
			EndIf;
			Organization = SettingsValueCached.GetDefaultOrganization(Organization);
			Parameters.Property("Department", Department);
		EndIf;
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ProductsForRegistration, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ProductsForRegistration, "Department", Department, QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ToRegisterWorks, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(ToRegisterWorks, "Department", Department, QuickFilterStructure);
	
	Parameters.Property("RegistrationPeriod", RegistrationPeriod);
	If Not ValueIsFilled(RegistrationPeriod) Then
		RegistrationPeriod = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	Parameters.Property("Products", Products);
	Parameters.Property("Purpose", Purpose);
	Parameters.Property("SettingsState", SettingsState);
	
	Items.ProductsForRegistrationOrganization.Visible = MultipleCompanies;
	Items.ToRegisterWorksOrganization.Visible = MultipleCompanies;
	
	MetadataObjects = New Array;
	MetadataObjects.Add(Metadata.Documents.BackflushProduction);
	MetadataObjects.Add(Metadata.Documents.RecyclableWasteAllocation);
	
	Items.DecorationThereIsAnErrorTransferringReserves.Visible = False;	
	Items.DecorationThereAreExtraReserves.Visible = 
		AccumulationRegisters.CompanySafeStock.ThereAreExtraReserves(True) = "ThereAreExtraReserves";	
	
	If Parameters.Property("CurrentPageName") And ValueIsFilled(Parameters.CurrentPageName) Then
		Items.GroupPages.CurrentPage = Items[Parameters.CurrentPageName];
		CurrentItem = Items.GroupPages.CurrentPage;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(RegistrationPeriod);
	UpdateFilters();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("Organization");
		Settings.Delete("Department");
	Else
		If Not MultipleCompanies Then
			Settings["Organization"] = Undefined;
		ElsIf Parameters.Property("Organization") Then
			Settings["Organization"] = Parameters["Organization"];
		EndIf;
		Settings["Organization"] = SettingsValueCached.GetDefaultOrganization(Settings["Organization"]);
		
		If Parameters.Property("Department") Then
			Settings["Department"] = Parameters["Department"];
		EndIf;
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		Settings["RegistrationPeriod"] = Parameters["RegistrationPeriod"];
	EndIf;
	
	If Parameters.Property("Products") Then
		Settings["Products"] = Parameters["Products"];
	EndIf;
	
	If Parameters.Property("Purpose") Then
		Settings["Purpose"] = Parameters["Purpose"];
	EndIf;
	
	If Parameters.Property("SettingsState") Then
		Settings["SettingsState"] = Parameters["SettingsState"];
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CostGenerationModel_Update" Then
		
		UpdateListData_();
		
	ElsIf EventName = "Write_BackflushProduction"
		Or EventName = "Write_RecyclableWasteAllocation" Then
		
		UpdateListData_();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ProductsForRegistration, "Organization", Organization, QuickFilterStructure, Settings);
		ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ProductsForRegistration, "Department", Department, QuickFilterStructure, Settings);
		
		ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ToRegisterWorks, "Organization", Organization, QuickFilterStructure, Settings);
		ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(ToRegisterWorks, "Department", Department, QuickFilterStructure, Settings);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	TMCommonUseClient.StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, RegistrationPeriod, ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		RegistrationPeriod = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(RegistrationPeriod);
	EndIf;
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("StartDate",			New Structure("Type, Value", "Parameter", BegOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("EndDate",		New Structure("Type, Value", "Parameter", EndOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("RegistrationPeriod",	New Structure("Type, Value", "Parameter", PeriodParameter(RegistrationPeriod, TotalsAreCalculated)));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	RegistrationPeriod = AddMonth(RegistrationPeriod, Direction);
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(RegistrationPeriod);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("StartDate",			New Structure("Type, Value", "Parameter", BegOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("EndDate",		New Structure("Type, Value", "Parameter", EndOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("RegistrationPeriod",	 New Structure("Type, Value", "Parameter", PeriodParameter(RegistrationPeriod, TotalsAreCalculated)));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure MonthLineOnChange(Item)
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("StartDate",			New Structure("Type, Value", "Parameter", BegOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("EndDate",		New Structure("Type, Value", "Parameter", EndOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("RegistrationPeriod",	New Structure("Type, Value", "Parameter", PeriodParameter(RegistrationPeriod, TotalsAreCalculated)));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	Items.ProductsForRegistrationOrganization.Visible = Not ValueIsFilled(Organization);
	Items.ToRegisterWorksOrganization.Visible = Not ValueIsFilled(Organization);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Organization", New Structure("Type, Value", "Filter", Organization));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure FilterOrganizationClearing(Item, StandardProcessing)
	
	Items.ProductsForRegistrationOrganization.Visible = Not ValueIsFilled(Organization);
	Items.ToRegisterWorksOrganization.Visible = Not ValueIsFilled(Organization);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Organization", New Structure("Type, Value", "Filter", Organization));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	Items.ProductsForRegistrationDepartment.Visible = Not ValueIsFilled(Department);
	Items.ToRegisterWorksDepartment.Visible = Not ValueIsFilled(Department);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Department", New Structure("Type, Value", "Filter", Department));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure FilterDepartmentClearing(Item, StandardProcessing)
	
	Items.ProductsForRegistrationDepartment.Visible = Not ValueIsFilled(Department);
	Items.ToRegisterWorksDepartment.Visible = Not ValueIsFilled(Department);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Department", New Structure("Type, Value", "Filter", Department));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure ManufacturedProductOnChange(Item)
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Products", New Structure("Type, Value", "Filter", Products));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure ManufacturedProductClearing(Item, StandardProcessing)
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Products", New Structure("Type, Value", "Filter", Products));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	Items.ProductsForRegistrationPurpose.Visible = Not ValueIsFilled(Purpose);
	Items.ToRegisterWorksPurpose.Visible = Not ValueIsFilled(Purpose);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Purpose", New Structure("Type, Value", "Filter", Purpose));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure PurposeClearing(Item, StandardProcessing)
	
	Items.ProductsForRegistrationPurpose.Visible = Not ValueIsFilled(Purpose);
	Items.ToRegisterWorksPurpose.Visible = Not ValueIsFilled(Purpose);
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("Purpose", New Structure("Type, Value", "Filter", Purpose));
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure HyperlinkProductionDocumentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.OpenLog(LogParameters());
	
EndProcedure

&AtClient
Procedure SettingsStateOnChange(Item)
	
	If Not ValueIsFilled(SettingsState) Then
		FilterParameter	= New Structure("Type, Value", "Filter", Undefined);
	ElsIf SettingsState = "1" Then
		FilterParameter	= New Structure("Type, Value", "Filter", False);
	Else
		FilterParameter	= New Structure("Type, Value", "Filter", True);
	EndIf;
	
	FiltersStructure = New Structure;
	FiltersStructure.Insert("ConfigurationIsRequired", FilterParameter);
	
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupProducts_2 Then
		// StandardSubsystems.PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm.BackToPageViewWhenChangingPage");
		// End StandardSubsystems.PerformanceMeasurement
	Else
		// StandardSubsystems.PerformanceMeasurement
		PerformanceMonitorClient.TimeMeasurement(
			"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm.ToDesignOfWorkWhenChangingPage");
		// End StandardSubsystems.PerformanceMeasurement
	EndIf;
	
EndProcedure

&AtClient
Procedure DecorationThereIsAnErrorTransferringReservesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ShouldNotRunInBackground", True);
	FilterParameters.Insert("StartDate", TransferStartTime);
	FilterParameters.Insert("EventLogEvent", NameOfReserveTransferEvent());
	EventLogClient.OpenEventLog(FilterParameters);

EndProcedure

&AtClient
Procedure DecorationThereAreExtraReservesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	TransferReserves_();
EndProcedure

&AtServerNoContext
Function NameOfReserveTransferEvent()
	
	Return AccumulationRegisters.CompanySafeStock.NameOfReserveTransferEvent();
	
EndFunction

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Setting the color for cells that require customization
	// Products
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsForRegistrationSetting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsForRegistration.ConfigurationIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Works
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ToRegisterWorksSetting.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToRegisterWorks.ConfigurationIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Setting text and color for cells according to the main specification
	// Products
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsForRegistrationSpecificationRule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsForRegistration.RecordCostsByADocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsForRegistration.SpecificationRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text",  NStr("vi = '<bảng kê chi tiết các nguồn lực sản xuất chính>';
													|ru = '<основная спецификация>';
													|en = '<main BOM>'; fa = '<main BOM>';
													|it = '<specifica principale>';
													|pl = '<specyfikacja główna>';
													|tr = '<ana ürün reçetesi>'"));
	
	// Works
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ToRegisterWorksSpecificationRule.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToRegisterWorks.RecordCostsByADocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToRegisterWorks.SpecificationRule");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text",  NStr("vi = '<bảng kê chi tiết các nguồn lực sản xuất chính>';
													|ru = '<основная спецификация>';
													|en = '<main BOM>'; fa = '<main BOM>';
													|it = '<specifica principale>';
													|pl = '<specyfikacja główna>';
													|tr = '<ana ürün reçetesi>'"));
	
	// Without an appointment if the appointment is not filled.
	// Products
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsForRegistrationPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsForRegistration.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<without assignment>'; fa = '<بدون تخصیص>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	
	// Works
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ToRegisterWorksPurpose.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToRegisterWorks.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không mục đích>';
													|ru = '<без назначения>';
													|en = '<without assignment>'; fa = '<بدون تخصیص>';
													|it = '<senza assegnazione>';
													|pl = '<bez przeznaczenia>';
													|tr = '<atamasız>'"));
	
	// Without a series, if the series is not filled.

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsForRegistrationSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ProductsForRegistration.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có lô>';
													|ru = '<без серии>';
													|en = '<without batch>'; fa = '<without batch>';
													|it = '<senza serie>';
													|pl = '<bez serii>';
													|tr = '<partisiz>'"));
	
EndProcedure

#Region ServiceCommandHandlers

&AtClient
Procedure ChangingCompletionModel(Result, AdditionalParameters) Export
	
	Item = Items[AdditionalParameters]; // FormTable - form table
	Item.Refresh();
	
EndProcedure

&AtClient
Procedure ProcessQuestionNotSelected(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		TMCommonUseClient.OpenLog(LogParameters());
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ToDesignGeneralClearModelServer(Rows)
	
	ParametersTable = New ValueTable;
	ParametersTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	ParametersTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	ParametersTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	
	For Each CurRow In Rows Do
		FillPropertyValues(ParametersTable.Add(), CurRow);
	EndDo;
	
	ParametersTable.GroupBy("Department, Products, Characteristic");
	
	For Each CurRow In ParametersTable Do
		
		Record = InformationRegisters.CostGenerationModels.CreateRecordManager();
		
		FillPropertyValues(Record, CurRow);
		
		Record.CostGenerationModel	= Undefined;
		Record.AllocatedAccordingToRule			= Undefined;
		Record.BillOfMaterials					= Undefined;
		Record.ConfigurationIsRequired			= True;
		Record.RecordCostsByADocument	= False;
		
		Record.Write(True);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ToIssueProductsIssueAccordingToTheSettingsCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Result = DocumentsOnParameters(AdditionalParameters);
		ProductionClient.ProcessGeneratedDocuments(ThisForm, Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

#Region TransferReserves_

&AtClient
Procedure TransferReserves_()		
	
	Items.DecorationThereAreExtraReserves.Visible = False;
	
	BackgroundJob = TransferReserves_Server();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterTransferringReserves", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function TransferReserves_Server()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chuyển dự trữ hàng hóa của doanh nghiệp';
																	|ru = 'Перенос резервов товаров организаций';
																	|en = 'Transfer company goods reserves'; fa = 'Transfer company goods reserves';
																	|it = 'Trasferimento delle scorte di merci delle società';
																	|pl = 'Przenoszenie rezerw towarów firm';
																	|tr = 'İş yerlerinin ürün rezervlerinin aktarılması'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("DataProcessors.LogOfIntercompanyDocuments.AllocateReservesByPeriod",
		New Structure, BackgroundExecutionParameters);
		
	TransferStartTime = CurrentSessionDate();
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterTransferringReserves(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			ProcessResultsOfBackgroundTasksByReserves(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = 'Görev gerçekleştirmesinin bitememe nedeni: %Cause%'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultsOfBackgroundTasksByReserves(AddressInTempStorage)
	
	Result = GetFromTempStorage(AddressInTempStorage); 
	
	Items.DecorationThereAreExtraReserves.Visible          = Result.ExcessReserves = "ThereAreExtraReserves";	
	Items.DecorationThereIsAnErrorTransferringReserves.Visible = Result.ExcessReserves = "Error";	
	
	Items.ProductsForRegistration.Refresh();
	
EndProcedure

#EndRegion


&AtServer
Procedure UpdateFilters()
	
	Items.ProductsForRegistrationOrganization.Visible		= Not ValueIsFilled(Organization);
	Items.ProductsForRegistrationDepartment.Visible	= Not ValueIsFilled(Department);
	Items.ProductsForRegistrationPurpose.Visible		= Not ValueIsFilled(Purpose);
	
	Items.ToRegisterWorksOrganization.Visible		= Not ValueIsFilled(Organization);
	Items.ToRegisterWorksDepartment.Visible	= Not ValueIsFilled(Department);
	Items.ToRegisterWorksPurpose.Visible		= Not ValueIsFilled(Purpose);
	
	If Not ValueIsFilled(SettingsState) Then
		FilterParameter	= New Structure("Type, Value", "Filter", Undefined);
	ElsIf SettingsState = "1" Then
		FilterParameter	= New Structure("Type, Value", "Filter", False);
	Else
		FilterParameter	= New Structure("Type, Value", "Filter", True);
	EndIf;
	
	FiltersStructure	= New Structure;
	FiltersStructure.Insert("StartDate",					New Structure("Type, Value", "Parameter", BegOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("EndDate",				New Structure("Type, Value", "Parameter", EndOfMonth(RegistrationPeriod)));
	FiltersStructure.Insert("RegistrationPeriod",			New Structure("Type, Value", "Parameter", PeriodParameter(RegistrationPeriod, TotalsAreCalculated)));
	FiltersStructure.Insert("TextSettingsNotSet",		New Structure("Type, Value", "Parameter", NStr("vi = '<Không có cài đặt được chỉ định>';
																										|ru = '<Настройки не заданы>';
																										|en = '<Settings are not configured>'; fa = '<Settings are not configured>';
																										|it = '<Impostazioni non stabilite>';
																										|pl = '<Ustawienia nie są określone>';
																										|tr = '<Ayarlar yapılmadı>'")));
	FiltersStructure.Insert("Organization",				New Structure("Type, Value", "Filter", Organization));
	FiltersStructure.Insert("Department",				New Structure("Type, Value", "Filter", Department));
	FiltersStructure.Insert("Products",				New Structure("Type, Value", "Filter", Products));
	FiltersStructure.Insert("Purpose",					New Structure("Type, Value", "Filter", Purpose));
	FiltersStructure.Insert("ConfigurationIsRequired",			FilterParameter);
	
	SetFilters(ThisForm.ProductsForRegistration, FiltersStructure);
	SetFilters(ThisForm.ToRegisterWorks, FiltersStructure);
	
EndProcedure

&AtClient
Procedure UpdateListData_(Result = Undefined, AdditionalParameters = Undefined) Export
	
	Items.ProductsForRegistration.Refresh();
	Items.ToRegisterWorks.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilters(DynamicList, FiltersStructure)
	
	For Each CurrFilter In FiltersStructure Do
		
		If CurrFilter.Value.Type = "Parameter" Then
			CommonClientServer.SetDynamicListParameter(
			DynamicList,
			CurrFilter.Key,
			CurrFilter.Value.Value,
			ValueIsFilled(CurrFilter.Value.Value));
		Else
			CommonClientServer.SetDynamicListFilterItem(
				DynamicList,
				CurrFilter.Key,
				CurrFilter.Value.Value,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(CurrFilter.Value.Value));
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function DocumentsOnParameters(DocumentParameters_)
	
	Return DataProcessors.RegisterBackflushProduction.GenerateDocumentsByParameters(DocumentParameters_);
	
EndFunction

&AtServerNoContext
Function PeriodParameter(RegistrationPeriod, TotalsAreCalculated)
	
	PeriodParameter = EndOfMonth(RegistrationPeriod) + 1;
	
	ProductTotal = AccumulationRegisters.CompanyGoods.GetMaxTotalsPeriod() + 1;
	ResultsOfWorks = AccumulationRegisters.MaterialsAndWorksInProduction.GetMaxTotalsPeriod() + 1;
	
	TotalsAreCalculated = PeriodParameter <= ProductTotal
						And PeriodParameter <= ResultsOfWorks;
	
	If Not TotalsAreCalculated Then
		PeriodParameter = Undefined;
	EndIf;
	
	Return PeriodParameter;
	
EndFunction

&AtServer
Function LogParameters()
	
	LogParameters = New Structure;
	LogParameters.Insert("FormAssignmentKey", "BackflushProduction");
	LogParameters.Insert("WorkplaceName", "LogOfProductionDocuments");
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ sản xuất';
												|ru = 'Документы производства';
												|en = 'Production documents'; fa = 'اسناد تولید';
												|it = 'Documenti di produzione';
												|pl = 'Dokumenty produkcji';
												|tr = 'Üretim belgeleri'"));
	ListFormSelections = New Structure;
	ListFormSelections.Insert("Period", New StandardPeriod(BegOfMonth(RegistrationPeriod), EndOfMonth(RegistrationPeriod)));
	ListFormSelections.Insert("Organization", Organization);
	ListFormSelections.Insert("Department", Department);
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID("Document.BackflushProduction"));
	FilterDocumentTypes.Add(Common.MetadataObjectID("Document.RecyclableWasteAllocation"));
	ListFormSelections.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	FilterBusinessTransactions = New ValueList;
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.ProductsRelease);
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.ExpensingToProductionLots);
	ListFormSelections.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	LogParameters.Insert("ListFormSelections", ListFormSelections);
	
	Return LogParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region EventHandlersForTableElementsToDesign

&AtClient
Procedure ProductsForRegistrationSelection(Item, RowSelected, Field, StandardProcessing)
	
	GeneralRequirementsForRegistration("ProductsForRegistration", Field);
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsForWorkDesign

&AtClient
Procedure ToRegisterWorksSelection(Item, RowSelected, Field, StandardProcessing)
	
	GeneralRequirementsForRegistration("ToRegisterWorks", Field);
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsForLayout

&AtClient
Procedure GeneralRequirementsForRegistration(TSName, Field)
	
	ThisIsRequiredField = False;
	
	If TSName = "ProductsForRegistration"
		And Field.Name = "ProductsForRegistrationSetting" Then
		ThisIsRequiredField = True;
	ElsIf TSName = "ToRegisterWorks"
		And Field.Name = "ToRegisterWorksSetting" Then
		ThisIsRequiredField = True;
	EndIf; 
	
	CurrentData = Items[TSName].CurrentData;
	
	If ThisIsRequiredField
		And Not CurrentData = Undefined
		And Not (OnlyViewingCostGenerationModel
			And CurrentData.ConfigurationIsRequired) Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CostGenerationModel",	CurrentData.CostGenerationModel);
		FormParameters.Insert("AllocatedAccordingToRule",			CurrentData.SpecificationRule);
		FormParameters.Insert("BillOfMaterials",					CurrentData.SpecificationRule);
		FormParameters.Insert("RecordCostsByADocument",	CurrentData.RecordCostsByADocument);
		FormParameters.Insert("ConfigurationIsRequired",			CurrentData.ConfigurationIsRequired);

		FilterParameters = New Structure("Department, Products, Characteristic");
		FillPropertyValues(FilterParameters, CurrentData);
		FormParameters.Insert("FilterParameters", FilterParameters);
		
		CallbackDescription = New CallbackDescription("ChangingCompletionModel", ThisForm, TSName);
		
		OpenForm(
			"DataProcessor.RegisterBackflushProduction.Form.FormSetUpCostGenerationModel",
			FormParameters,
			ThisForm,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region HandlersForPageLayoutCommandsProducts

&AtClient
Procedure ToIssueProductsIssueAccordingToTheSettings(Command)
	
	ToDesignGeneralDesignAccordingToSettings("ProductsForRegistration");
	
EndProcedure

&AtClient
Procedure ToTheDesignOfTheProductsProductionWithoutOrder(Command)
	
	ForRegistrationGeneralProductionWithoutOrder("ProductsForRegistration");
	
EndProcedure

&AtClient
Procedure ForRegistrationProductsDistributionOfReturnableWaste(Command)
	
	ForRegistrationAndDistributionOfReturnableWaste("ProductsForRegistration");
	
EndProcedure

&AtClient
Procedure ToDesignProductsUpdate(Command)
	
	GeneralRequirementsForRegistration_(Items.ProductsForRegistration);
	
EndProcedure

&AtClient
Procedure ToTheDesignOfProductsToCustomizeTheModel(Command)
	
	GoToDesignAndConfigureModel("ProductsForRegistration");
	
EndProcedure

&AtClient
Procedure ToDesignProductsToCleanTheModel(Command)
	
	ToDesignGeneralClearModel("ProductsForRegistration");
	
EndProcedure

#EndRegion

#Region HandlersOfPageCommandsForWorkDesign

&AtClient
Procedure ForTheDesignOfTheWorkMakeItAccordingToTheSetting(Command)
	
	ToDesignGeneralDesignAccordingToSettings("ToRegisterWorks");
	
EndProcedure

&AtClient
Procedure ToTheDesignOfTheWorkProductionWithoutAnOrder(Command)
	
	ForRegistrationGeneralProductionWithoutOrder("ToRegisterWorks");
	
EndProcedure

&AtClient
Procedure ToTheDesignOfTheWorkDistributionOfReturnableWaste(Command)
	
	ForRegistrationAndDistributionOfReturnableWaste("ToRegisterWorks");
	
EndProcedure

&AtClient
Procedure ToTheDesignOfTheWorkUpdate(Command)
	
	GeneralRequirementsForRegistration_(Items.ToRegisterWorks);
	
EndProcedure

&AtClient
Procedure ForTheDesignOfTheWorkConfigureTheModel(Command)
	
	GoToDesignAndConfigureModel("ToRegisterWorks");
	
EndProcedure

&AtClient
Procedure ToTheDesignOfTheWorkClearTheModel(Command)
	
	ToDesignGeneralClearModel("ToRegisterWorks");
	
EndProcedure

#EndRegion

#Region HandlersForPageLayoutCommandsMain

&AtClient
Procedure ToDesignGeneralDesignAccordingToSettings(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ModelNotSpecified			= 0;
	ProductsAccordingToSpecification	= New Array;
	ProductsByRule		= New Array;
	TypeSpecification			= New TypeDescription("CatalogRef.BillsOfMaterials");
	TypeDistributionRule	= New TypeDescription("CatalogRef.CostAllocationRules");
	ReleaseToDivision	= PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit");
	ReleaseToWarehouse			= PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
	Work_Type				= PredefinedValue("Enum.ItemsTypes.Work_5");
	ModelProduction			= PredefinedValue("Enum.ModelTypesOfCosting.ReleaseAtCalculatedCost");
	ModelReturnWaste	= PredefinedValue("Enum.ModelTypesOfCosting.ProductionIssueAtFixedCost");
	
	For Each AlCollections In SelectedRows Do
		
		RowData = Items[TSName].RowData(AlCollections);
		
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		RecipientDivision	= RowData.ItemsType = Work_Type;
		Recipient				= ?(RecipientDivision, RowData.Department, RowData.Storeroom);
		DirectionOfProductionIssue		= ?(RecipientDivision, ReleaseToDivision, ReleaseToWarehouse);
		RuleRequired		= RowData.CostGenerationModel = ModelReturnWaste;
		SpecificationRequired	= RowData.CostGenerationModel = ModelProduction;
		
		
		ProductStructure = ProductionClientServer.StructureProductLine();
		FillPropertyValues(ProductStructure, RowData);
		
		If Not RowData.Property("Organization") Then
			ProductStructure.Organization = Organization;
		EndIf;
		
		If Not RowData.Property("Department") Then
			ProductStructure.Department = Department;
		EndIf;
		
		ProductStructure.DirectionOfProductionIssue		= DirectionOfProductionIssue;
		ProductStructure.Count				= RowData.ToRegister;
		ProductStructure.Recipient				= Recipient;
		ProductStructure.BillOfMaterials			= TypeSpecification.AdjustValue(RowData.SpecificationRule);
		ProductStructure.AllocatedAccordingToRule	= TypeDistributionRule.AdjustValue(RowData.SpecificationRule);
		
		If SpecificationRequired Then
			If RowData.RecordCostsByADocument Then
				ProductStructure.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.ByProductBOM");
			Else
				ProductStructure.GroupCosts = PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.CostsAreNotSpecified");
			EndIf;
			ProductsAccordingToSpecification.Add(ProductStructure);
		EndIf;
		
		If RuleRequired Then
			ProductsByRule.Add(ProductStructure);
		EndIf;
		
		If Not SpecificationRequired
			And Not RuleRequired Then
			ProductStructure.ErrorInModelSettings = True;
			ModelNotSpecified = ModelNotSpecified + 1;
		EndIf;
		
	EndDo;
	
	QueryText = NStr("vi = 'Xảy ra lỗi trong khi kiểm tra các cài đặt của mô hình lập giá trị:';
					|ru = 'При проверке настроек модели формирования стоимости возникли ошибки:';
					|en = 'Errors occurred when checking settings of the cost generation model:'; fa = 'Errors occurred when checking settings of the cost generation model:';
					|it = 'Durante il controllo delle impostazioni del modello di generazione del costo, si sono verificati degli errori:';
					|pl = 'Podczas weryfikacji ustawień modelu tworzenia wartości wystąpiły błędy:';
					|tr = 'Maliyet düzenleme modelinin ayarları kontrol edilirken hata oluştu:'");
	QueryText = QueryText + Chars.LF + NStr("vi = 'Không có mô hình tạo giá trị được chỉ định (%1 trên %2)';
											|ru = 'Не указана модель формирования стоимости (%1 из %2)';
											|en = 'Cost generation model is not specified (%1 out of %2)'; fa = 'Cost generation model is not specified (%1 out of %2)';
											|it = 'Modello di generazione costo (%1 da %2) non è specificato';
											|pl = 'Nie podano modelu tworzenia wartości(%1 z %2)';
											|tr = 'Maliyet düzenleme modeli belirtilmedi (%2 üzerinden %1)'");
	
	DocumentParameters_ = ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders();
	DocumentParameters_.ProductsAccordingToSpecification = ProductsAccordingToSpecification;
	DocumentParameters_.ProductsByRule = ProductsByRule;
	DocumentParameters_.AutoFill = True;
	DocumentParameters_.RegistrationPeriod = RegistrationPeriod;
	
	DocumentParameters_.ListOfData.Add("RecyclableWaste");
	DocumentParameters_.ListOfData.Add("MaterialsAndServices");
	DocumentParameters_.ListOfData.Add("LaborCosts");
	
	DocumentForm = GetForm("Document.BackflushProduction.ObjectForm",, ThisForm);
	DocumentParameters_.FormObjects.Insert("BackflushProduction", DocumentForm.Object);
	
	DocumentForm = GetForm("Document.RecyclableWasteAllocation.ObjectForm",, ThisForm);
	DocumentParameters_.FormObjects.Insert("RecyclableWasteAllocation", DocumentForm.Object);
	
	If ModelNotSpecified = SelectedRows.Count() Then
		ShowMessageBox(,NStr("vi = 'Không có dòng nào được cài đặt. Không có chứng từ sẽ được tạo ra.';
							|ru = 'Ни для одной строки не заданы настройки. Не будет сформировано ни одного документа.';
							|en = 'No lines with specified settings. No document will be generated.'; fa = 'No lines with specified settings. No document will be generated.';
							|it = 'Non ci sono impostazioni per alcuna riga. Nessun documento verrà generato.';
							|pl = 'Ani jeden wiersz nie jest skonfigurowany. Nie będzie utworzono ani jednego dokumentu.';
							|tr = 'Herhangi satır için ayar yapılmadı. Herhangi bir belge oluşturulmayacaktır.'"));
		Return;
	EndIf;
	
	If Not ModelNotSpecified = 0 Then
		
		QueryText = QueryText + Chars.LF + NStr("vi = 'Chứng từ về các dòng như vậy sẽ không được tạo ra. Tiếp tục?';
												|ru = 'Документы по таким строкам сформированы не будут. Продолжить?';
												|en = 'Documents will not be generated for such lines. Continue?'; fa = 'Documents will not be generated for such lines. Continue?';
												|it = 'I documenti per queste righe non verranno generati. Continuare?';
												|pl = 'Dokumenty dla takich wierszy nie będą utworzone. Kontynuować?';
												|tr = 'Bu türdeki satırlara yönelik belgeler oluşturulmayacaktır. Devam edilsin mi?'");
		QueryText = StrTemplate(QueryText, ModelNotSpecified, SelectedRows.Count());
		
		CallbackDescription = New CallbackDescription("ToIssueProductsIssueAccordingToTheSettingsCompletion", ThisForm, DocumentParameters_);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		Result = DocumentsOnParameters(DocumentParameters_);
		ProductionClient.ProcessGeneratedDocuments(ThisForm, Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ForRegistrationGeneralProductionWithoutOrder(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ProductsAccordingToSpecification	= New Array;
	ReleaseToDivision	= PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit");
	ReleaseToWarehouse			= PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
	Work_Type				= PredefinedValue("Enum.ItemsTypes.Work_5");
	TypeSpecification			= New TypeDescription("CatalogRef.BillsOfMaterials");
	
	For Each AlCollections In SelectedRows Do
		
		RowData = Items[TSName].RowData(AlCollections);
		
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		RecipientDivision	= RowData.ItemsType = Work_Type;
		Recipient				= ?(RecipientDivision, RowData.Department, RowData.Storeroom);
		DirectionOfProductionIssue		= ?(RecipientDivision, ReleaseToDivision, ReleaseToWarehouse);
		
		ProductStructure = ProductionClientServer.StructureProductLine();
		FillPropertyValues(ProductStructure, RowData);
		
		If Not RowData.Property("Organization") Then
			ProductStructure.Organization = Organization;
		EndIf;
		
		If Not RowData.Property("Department") Then
			ProductStructure.Department = Department;
		EndIf;
		
		If Not RowData.Property("Purpose") Then
			ProductStructure.Purpose = Purpose;
		EndIf;
		
		ProductStructure.GroupCosts	= PredefinedValue("Enum.GroupingsOfCostsInBackflushProduction.ByProducts");
		ProductStructure.DirectionOfProductionIssue	= DirectionOfProductionIssue;
		ProductStructure.Count			= RowData.ToRegister;
		ProductStructure.Recipient			= Recipient;
		ProductStructure.BillOfMaterials		= TypeSpecification.AdjustValue(RowData.SpecificationRule);
		ProductsAccordingToSpecification.Add(ProductStructure);
		
	EndDo;
	
	DocumentParameters_ = ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders();
	DocumentParameters_.ProductsAccordingToSpecification = ProductsAccordingToSpecification;
	DocumentParameters_.RegistrationPeriod = RegistrationPeriod;
	DocumentParameters_.ListOfData.Add("RecyclableWaste");
	DocumentParameters_.ListOfData.Add("MaterialsAndServices");
	DocumentParameters_.ListOfData.Add("LaborCosts");
	
	DocumentForm = GetForm("Document.BackflushProduction.ObjectForm",, ThisForm);
	DocumentParameters_.FormObjects.Insert("BackflushProduction", DocumentForm.Object);
	
	Result = DocumentsOnParameters(DocumentParameters_);
	ProductionClient.ProcessGeneratedDocuments(ThisForm, Result);
	
EndProcedure

&AtClient
Procedure ForRegistrationAndDistributionOfReturnableWaste(TSName)
	
	SelectedRows = Items[TSName].SelectedRows;
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(SelectedRows, LogParameters()) Then
		Return;
	EndIf;
	
	ProductsByRule		= New Array;
	ReleaseToDivision	= PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit");
	ReleaseToWarehouse			= PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse");
	Work_Type				= PredefinedValue("Enum.ItemsTypes.Work_5");
	TypeDistributionRule	= New TypeDescription("CatalogRef.CostAllocationRules");
	
	For Each AlCollections In SelectedRows Do
		
		RowData = Items[TSName].RowData(AlCollections);
		
		If RowData = Undefined Then
			Continue;
		EndIf;
		
		RecipientDivision	= RowData.ItemsType = Work_Type;
		Recipient				= ?(RecipientDivision, RowData.Department, RowData.Storeroom);
		DirectionOfProductionIssue		= ?(RecipientDivision, ReleaseToDivision, ReleaseToWarehouse);
		
		ProductStructure = ProductionClientServer.StructureProductLine();
		FillPropertyValues(ProductStructure, RowData);
		
		If Not RowData.Property("Organization") Then
			ProductStructure.Organization = Organization;
		EndIf;
		
		If Not RowData.Property("Department") Then
			ProductStructure.Department = Department;
		EndIf;
		
		If Not RowData.Property("Purpose") Then
			ProductStructure.Purpose = Purpose;
		EndIf;
		
		ProductStructure.DirectionOfProductionIssue		= DirectionOfProductionIssue;
		ProductStructure.Count				= RowData.ToRegister;
		ProductStructure.Recipient				= Recipient;
		ProductStructure.AllocatedAccordingToRule	= TypeDistributionRule.AdjustValue(RowData.SpecificationRule);
		
		ProductsByRule.Add(ProductStructure);
		
	EndDo;
	
	DocumentParameters_ = ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders();
	DocumentParameters_.ProductsByRule = ProductsByRule;
	DocumentParameters_.RegistrationPeriod = RegistrationPeriod;
	
	DocumentForm = GetForm("Document.RecyclableWasteAllocation.ObjectForm",, ThisForm);
	DocumentParameters_.FormObjects.Insert("RecyclableWasteAllocation", DocumentForm.Object);
	
	Result = DocumentsOnParameters(DocumentParameters_);
	ProductionClient.ProcessGeneratedDocuments(ThisForm, Result);
	
EndProcedure

&AtClient
Procedure GeneralRequirementsForRegistration_(Item)
	
	// StandardSubsystems.PerformanceMeasurement
	If Item.Name = "ProductsForRegistration" Then
		CommandName = "ToDesignProductsUpdate";
	Else
		CommandName = "ToTheDesignOfTheWorkUpdate";
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm.Command." + CommandName);
	// End StandardSubsystems.PerformanceMeasurement
	
	Item.Refresh();
	
EndProcedure

&AtClient
Procedure GoToDesignAndConfigureModel(TSName)
	
	// StandardSubsystems.PerformanceMeasurement
	If TSName = "ProductsForRegistration" Then
		CommandName = "ToTheDesignOfProductsToCustomizeTheModel";
	Else
		CommandName = "ForTheDesignOfTheWorkConfigureTheModel";
	EndIf;
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm.Command." + CommandName);
	// End StandardSubsystems.PerformanceMeasurement
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If Not SelectedRows.Count() = 0 Then
		
		FormParameters = New Structure("CostGenerationModel, RecordCostsByADocument, BillOfMaterials, AllocatedAccordingToRule, FilterParameters");
		
		CostGenerationModel	= Undefined;
		SpecificationRule			= Undefined;
		RecordCostsByADocument	= Undefined;
		ConfigurationIsRequired			= Undefined;
		
		OneModel = True;
		OneSpecificationRule = True;
		OneReflectionIsZataratInDocument = True;
		OneConfigurationIsRequired = True;
		
		FilterParameters = New Array;
		
		For Each CurRow In SelectedRows Do
			
			RowData = Items[TSName].RowData(CurRow);
			
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			If CostGenerationModel = Undefined Then
				CostGenerationModel	= RowData.CostGenerationModel;
				SpecificationRule			= RowData.SpecificationRule;
				RecordCostsByADocument	= RowData.RecordCostsByADocument;
				ConfigurationIsRequired			= RowData.ConfigurationIsRequired;
			EndIf;
			
			If Not CostGenerationModel = RowData.CostGenerationModel Then
				OneModel = False;
			EndIf;
			
			If Not SpecificationRule = RowData.SpecificationRule Then
				OneSpecificationRule = False;
			EndIf;
			
			If Not RecordCostsByADocument = RowData.RecordCostsByADocument Then
				OneReflectionIsZataratInDocument = False;
			EndIf;
			
			If Not ConfigurationIsRequired = RowData.ConfigurationIsRequired Then
				OneConfigurationIsRequired = False;
			EndIf;
			
			Parameter = New Structure("Department, Products, Characteristic, LineOfBusiness");
			FillPropertyValues(Parameter, RowData);
			FilterParameters.Add(Parameter);
			
		EndDo;
		
		FormParameters.Insert("FilterParameters", FilterParameters);
		
		If OneModel Then
			FormParameters.Insert("CostGenerationModel", CostGenerationModel);
		EndIf;
		
		If OneSpecificationRule Then
			FormParameters.Insert("AllocatedAccordingToRule", SpecificationRule);
			FormParameters.Insert("BillOfMaterials", SpecificationRule);
		EndIf;
		
		If OneReflectionIsZataratInDocument Then
			FormParameters.Insert("RecordCostsByADocument", RecordCostsByADocument);
		EndIf;
		
		If OneConfigurationIsRequired Then
			FormParameters.Insert("ConfigurationIsRequired", ConfigurationIsRequired);
		EndIf;
		
		CallbackDescription = New CallbackDescription("ChangingCompletionModel", ThisForm, TSName);
		
		OpenForm(
			"DataProcessor.RegisterBackflushProduction.Form.FormSetUpCostGenerationModel",
			FormParameters,
			ThisForm,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ToDesignGeneralClearModel(TSName)
	
	// StandardSubsystems.PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm.Command." + TSName + "ClearModel");
	// End StandardSubsystems.PerformanceMeasurement
	
	SelectedRows = Items[TSName].SelectedRows;
	
	If Not SelectedRows.Count() = 0 Then
		
		Rows = New Array;
		
		For Each CurRow In SelectedRows Do
			
			RowData = Items[TSName].RowData(CurRow);
			If RowData = Undefined Then
				Continue;
			EndIf;
			
			StringStructure = New Structure("Department, Products, Characteristic");
			FillPropertyValues(StringStructure, RowData);
			Rows.Add(StringStructure);
			
		EndDo;
		
		ToDesignGeneralClearModelServer(Rows);
		
		Items[TSName].Refresh();
		
	EndIf;
	
EndProcedure

#EndRegion
