////////////////////////////////////////////////////////////////
// The "Internal Processing Server" module contains procedures and functions for 
// working with the internal processing mechanism.
//
////////////////////////////////////////////////////////////////

#Region Public

#Region FillType

// Fills in the Property ownership attribute available in the table rows
// 
//	Parameters:
//		Form   - ClientApplicationForm - form owner of the processed table
//		Table - FormDataCollection       - table being processed
//		Rows  - Array, Undefined       - array of processed strings
//
Procedure FillInProductOwnerIsAvailableInTable(Form, Table, Rows = Undefined) Export
	
	If Not Form.UseInternalSubcontracting
		Or Table.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.LineNumber AS LineNumber,
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
	|	NOT ISNULL(Assignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|		VALUE(Enum.AssignmentTypes.Giveaway21),
	|		VALUE(Enum.AssignmentTypes.ProvidedMaterials22),
	|		VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|		VALUE(Enum.AssignmentTypes.SuppliedProducts22),
	|		VALUE(Enum.AssignmentTypes.Giveaway2_5)) AS FINISHEDProductOwnerIsAvailable
	|FROM
	|	Table AS Table
	|	
	|	LEFT JOIN Catalog.Assignments AS Assignments
	|	ON Table.Purpose = Assignments.Ref
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Table", Table.Unload(Rows, "LineNumber, Purpose"));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		CurrentData = Table[Selection.LineNumber - 1];
		
		FillPropertyValues(CurrentData, Selection, "FINISHEDProductOwnerIsAvailable");
		
		If Not CurrentData.FINISHEDProductOwnerIsAvailable And ValueIsFilled(CurrentData.ProductOwner) Then
			CurrentData.ProductOwner = Undefined;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the service Attribute "The owner of the department is available" in the line according to the specified assignment
//
// Parameters:
//  CurrentData		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action,
//  														   The value - Structure - activity settings.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInProductOwnerIsAvailable(CurrentData, StructureOfActions, CachedValues) Export
	
	If Not CommonClientServer.HasAttributeOrObjectProperty(CurrentData, "FINISHEDProductOwnerIsAvailable") Then
		Return;
	EndIf;
	
	FINISHEDProductOwnerIsAvailable = True;
	
	If ValueIsFilled(CurrentData.Purpose) Then
		
		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentData.Purpose);
		
		If PropertiesPurpose = Undefined Then 
			
			AssignmentProperties = Catalogs.Assignments.AssignmentProperties(CurrentData.Purpose);
			PropertiesPurpose = AssignmentProperties.Get(CurrentData.Purpose);
			
			CachedValues.AssignmentProperties.Insert(CurrentData.Purpose, PropertiesPurpose);
			
		EndIf;
		
		FINISHEDProductOwnerIsAvailable =
			Not PropertiesPurpose.ThisIsAppointmentOfGiver2_5
			And True;
		
	EndIf;
	
	CurrentData.FINISHEDProductOwnerIsAvailable = FINISHEDProductOwnerIsAvailable;
	
	If Not CurrentData.FINISHEDProductOwnerIsAvailable Then
		CurrentData.ProductOwner = Undefined;
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the availability of the product owner.
//
// Parameters:
//  StructureOfActions - Structure
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CompleteQueryTextProductOwnerIsAvailable(StructureOfActions, QueryDetails, CachedValues) Export
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction("FillInProductOwnerIsAvailable", StructureOfActions, CachedValues) Then
	
		QueryText = "
		|SELECT ALLOWED
		|	DataSource.IdOfTTRow AS IdOfTTRow,
		|	NOT ISNULL(CatAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
		|		VALUE(Enum.AssignmentTypes.Giveaway21),
		|		VALUE(Enum.AssignmentTypes.ProvidedMaterials22),
		|		VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
		|		VALUE(Enum.AssignmentTypes.SuppliedProducts22),
		|		VALUE(Enum.AssignmentTypes.Giveaway2_5)) AS FINISHEDProductOwnerIsAvailable
		|FROM
		|	TTDataSource AS DataSource
		|	
		|	LEFT JOIN Catalog.Assignments AS CatAssignments
		|	ON CatAssignments.Ref = DataSource.Purpose
		|";
		
		QueryDetails.QueriesTexts.Add(QueryText, "FINISHEDProductOwnerIsAvailable");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

// Sets the Conditional appearance of the "Product Owner" field
//	
// Parameters:
//  Form          - ClientApplicationForm - the form for which the conditional design is configured.
//	ObjectName     - String           - object name.
//  TSName          - String           - Name of the form table.
//  ItemsNames - Structure        - names of the form elements.
//  DataPaths    - Structure        - the path to the data.
// 
Procedure SetConditionalAppearanceOfProductOwnerField(Form, ObjectName, TSName, ItemsNames, DataPaths = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	
	// Setting the visibility of the "Product Owner" column
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ProductOwner);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "InternalSubcontracting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Visible", False);
	
	// Setting the availability/obligation of the "Product Owner" column
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ProductOwner);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".FINISHEDProductOwnerIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly",        True);
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text",                 NStr("vi = '<đối với sản phẩm riêng>';
																						|ru = '<для собственных изделий>';
																						|en = '<for own products>'; fa = '<for own products>';
																						|it = '<для собственных изделий>';
																						|pl = '<for own products>';
																						|tr = '<yerel nihai ürünler için>'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
	
	// Setting the presentation of the product owner - giver
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ProductOwner);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".FINISHEDProductOwnerIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProductOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProductOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "MaterialProviderCompany");
	
	TheFieldText = CommonClientServer.StructureProperty(DataPaths, "TextOwnerGiver", "TextOwnerGiver");
	TheFieldText = New DataCompositionField(TheFieldText);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", TheFieldText);
	
	// Setting the representation of the product owner - the processor
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ProductOwner);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.FINISHEDProductOwnerIsAvailable");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProductOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProductOwner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "Organization");
	
	TheFieldText = CommonClientServer.StructureProperty(DataPaths, "TextOwnerProcessor", "TextOwnerProcessor");
	TheFieldText = New DataCompositionField(TheFieldText);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", TheFieldText);
	
EndProcedure

#EndRegion

#Region HandlersForMonthClosingStages

#Region CheckingBalancesForMakingReportsToGiver

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth
// 	CurrentParent - String - group ID.
//
Procedure AddStage_BalancesForReportingToGivers(StepsTable,CurrentParent) Export
	
	NewRow =  MonthEndTransactionsServer.AddStageToTable(
		StepsTable,
		CurrentParent,
		Catalogs.MonthEndClosingOperations.RegisterIntercompanyConsumptionReportsSubcontractingServicesDelivered);
	
	NewRow.MultilingualName = "vi = 'Lập bảng kê dành cho người đặt gia công giữa các doanh nghiệp';
								|ru = 'Оформление отчетов давальцам между организациями';
								|en = 'Register Intercompany consumption reports — Subcontracting services delivered';
								|it = 'Register Intercompany consumption reports — Subcontracting services delivered';
								|pl = 'Register Intercompany consumption reports — Subcontracting services delivered';
								|tr = 'İş yerleri arasında tedarikçi için tüketim raporlarının düzenlenmesi'"; // @NStr-1
		NewRow.PerformedManually = True;
	NewRow.ActionDesign =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InternalSubcontractingServer.Registration_BalancesForRegistrationOfReportsToGivers");
	NewRow.ActionUse =  MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"InternalSubcontractingServer.Using_BalancesForReportingToGivers");
	
	NewRow.ActionExecute  =  MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.Forms.WorkplaceForm.FullName(), True);
	
EndProcedure

// Stage handlers
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Using_BalancesForReportingToGivers(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	TheseAreHandlerParameters = HandlerParameters.Property("CalculationParameters");
	
	If TheseAreHandlerParameters Then
		CalculationParameters = HandlerParameters.CalculationParameters;
	Else
		CalculationParameters = HandlerParameters;
	EndIf;
	
	If CalculationParameters.Property("BeginOfPeriod") Then
		BeginOfPeriod = BegOfMonth(CalculationParameters.BeginOfPeriod);
	Else
		BeginOfPeriod = BegOfMonth(CalculationParameters.RegistrationPeriod);
	EndIf;
	
	RequestParametersForBalances = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.ParametersForRequestingReportBalancesForRegistration();
	RequestParametersForBalances.Organization = CalculationParameters.CompanyArray;
	RequestParametersForBalances.Month = BeginOfPeriod;
	RequestParametersForBalances.OnlyCompleted = True;
	
	Query = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.RequestRemainingReportsToBeProcessed(RequestParametersForBalances);
	
	// temporary table manager.
	DataInitialized = TheseAreHandlerParameters And HandlerParameters.Property("TempTablesManager");
	If DataInitialized Then
		Query.TempTablesManager = HandlerParameters.TempTablesManager;
	ElsIf TheseAreHandlerParameters Then
		HandlerParameters.Insert("TempTablesManager", New TempTablesManager);
		Query.TempTablesManager = HandlerParameters.TempTablesManager;
	Else
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query = RequestSchemes.SetRoomToTemporaryTable(Query, "BalancesForReportingToGivers");
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.BalancesForReportingToGivers = 0 Then
	
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có số dư để lập bảng kê cho bên đặt gia công giữa các doanh nghiệp.';
				|ru = 'Нет остатков к оформлению отчетов давальцам между организациями.';
				|en = 'There are no remaining goods to register ""Intercompany consumption reports — Subcontracting services delivered"".'; fa = 'There are no remaining goods to register ""Intercompany consumption reports — Subcontracting services delivered"".';
				|it = 'Нет остатков к оформлению отчетов давальцам между организациями.';
				|pl = 'There are no remaining goods to register ""Intercompany consumption reports — Subcontracting services delivered"".';
				|tr = 'İş yerleri arasında tedarikçi için tüketim raporlarının düzenlenmesine yönelik bakiye yoktur.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// Forms out the closing stage of the month.
// 
// Parameters:
// 	HandlerParameters - See MonthEndTransactionsServer.InitializeParametersOfMonthClosingStageHandlerForVerification
//
Procedure Registration_BalancesForRegistrationOfReportsToGivers(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Lập bảng kê';
													|ru = 'Оформить';
													|en = 'Register'; fa = 'ثبات';
													|it = 'Оформить';
													|pl = 'Register';
													|tr = 'Düzenle'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.
// 
// Parameters:
// 	TableOfChecks - See AuditOfSystemState.SystemStateCheckTable
//
Procedure DescriptionOfChecks_BalancesForMakingReportsToGivers(TableOfChecks) Export
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(
		TableOfChecks,
		"RegisterIntercompanyConsumptionReportsSubcontractingServicesDelivered",
		Catalogs.MonthEndClosingOperations.RegisterIntercompanyConsumptionReportsSubcontractingServicesDelivered,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeCalculation,
		"InternalSubcontractingServer.CheckingBalancesForMakingReportsToGivers");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chưa lập bảng kê cho người đặt gia công giữa các doanh nghiệp.';
			|ru = 'Не оформлены отчеты давальцам между организациями.';
			|en = '""Intercompany consumption reports — Subcontracting services delivered"" are not registered.'; fa = '""Intercompany consumption reports — Subcontracting services delivered"" are not registered.';
			|it = 'Не оформлены отчеты давальцам между организациями.';
			|pl = '""Intercompany consumption reports — Subcontracting services delivered"" are not registered.';
			|tr = 'İş yerleri arası tüketim raporu-Verilen fason hizmetleri henüz düzenlenmedi.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Theo tất cả lô hàng sản xuất đã hoàn thành cần lập bảng kê dành cho bên đặt gia công giữa các doanh nghiệp.';
			|ru = 'По всем завершенным партиям производства должны быть оформлены отчеты давальцу между организациями.';
			|en = '""Intercompany consumption reports — Subcontracting services delivered"" must be registered for all finished lots.'; fa = '""Intercompany consumption reports — Subcontracting services delivered"" must be registered for all finished lots.';
			|it = 'По всем завершенным партиям производства должны быть оформлены отчеты давальцу между организациями.';
			|pl = '""Intercompany consumption reports — Subcontracting services delivered"" must be registered for all finished lots.';
			|tr = 'Tamamlanan tüm üretim lotları için iş yerleri arası tüketim raporu-Verilen fason hizmetleri düzenlenmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

// Error logging.
// 
// Parameters:
// 	CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure CheckingBalancesForMakingReportsToGivers(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
	
	FieldList = New ValueList;
	FieldList.Add("Organization",        NStr("vi = 'Bên nhận gia công';
												|ru = 'Переработчик';
												|en = 'Subcontractor'; fa = 'پیمانکار فرعی';
												|it = 'Переработчик';
												|pl = 'Subcontractor';
												|tr = 'Fason üretici'",        Common.DefaultLanguageCode()));
	FieldList.Add("MaterialProvider",            NStr("vi = 'Bên đặt gia công';
														|ru = 'Давалец';
														|en = 'Material provider'; fa = 'تأمین‌کننده مواد';
														|it = 'Давалец';
														|pl = 'Material provider';
														|tr = 'Malzeme tedarikçisi'",             Common.DefaultLanguageCode()));
	FieldList.Add("ProductionLot", NStr("vi = 'Lô sản xuất';
										|ru = 'Партия производства';
										|en = 'Production lot'; fa = 'بچ تولید';
										|it = 'Lotto di produzione';
										|pl = 'Partia produkcji';
										|tr = 'Üretim lotu'", Common.DefaultLanguageCode()));
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"BalancesForReportingToGivers",
		NStr("vi = 'Đã phát hiện số dư cần lập bảng kê cho bên đặt gia công giữa các doanh nghiệp theo tên của bên nhận gia công ""%1"" vào cuối kỳ %2';
			|ru = 'Обнаружены остатки к оформлению отчетов давальцам между организации от имени переработчика ""%1"" на конец периода %2';
			|en = 'There is remaining stock to register intercompany consumption reports on behalf of the ""%1"" subcontractor at the end of the period %2'; fa = 'There is remaining stock to register intercompany consumption reports on behalf of the ""%1"" subcontractor at the end of the period %2';
			|it = 'Обнаружены остатки к оформлению отчетов давальцам между организации от имени переработчика ""%1"" на конец периода %2';
			|pl = 'There is remaining stock to register intercompany consumption reports on behalf of the ""%1"" subcontractor at the end of the period %2';
			|tr = '%2 dönemi sonunda %1 fason üreticiye iş yeri arasında tedarikçilere raporlanacak bakiyeler tespit edildi'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion