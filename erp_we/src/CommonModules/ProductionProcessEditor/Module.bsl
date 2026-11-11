////////////////////////////////////////////////////////////////////////////////
// Procedures and functions of the Production Process Editor
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region ManufacturingProcess

Procedure StructureOfProductionProcessInBackground(Parameters, StorageAddress) Export
	
	Result = ManufacturingProcessStructure(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#Region ProductionStage

// Sets the availability of stage elements by status
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	AttributeAvailability - Boolean
// 	BillOfMaterialsIsClosed - Boolean
// 	ElementPrefix - String
Procedure SetAvailabilityOfStageElementsByStatus(Form, AttributeAvailability, BillOfMaterialsIsClosed, ElementPrefix = "") Export
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	ItemArray = New Array;
	ItemArray.Add("StageNumber");
	ItemArray.Add("NextStageNo");
	ItemArray.Add("Department");
	ItemArray.Add("ProductionMethod");
	ItemArray.Add("QuantityOfProductUnitsLotsProducedSimultaneously");
	ItemArray.Add("PlanOperationsOfWorkCenterTypes");
	ItemArray.Add("WorkCenterTypes");
	ItemArray.Add("Partner");
	ItemArray.Add("Organization");
	ItemArray.Add("SubcontractorServices");
	ItemArray.Add("WorkScheduleOfPartner");
	ItemArray.Add("OperatingProcedureOfWorkCenterTypes");
	
	For Each TagName In ItemArray Do
		Form.Items[MatchingElements[TagName]].ReadOnly = Not AttributeAvailability;
	EndDo;
	
	ItemArray.Clear();
	ItemArray.Add("FillInTheTypesOfWorkCenters");
	ItemArray.Add("TypesOfWorkCentersAddAlternative");
	
	For Each TagName In ItemArray Do
		Form.Items[MatchingElements[TagName]].Enabled = AttributeAvailability;
	EndDo;
	
	// If the specification is closed, then we will make the rest of the details unavailable
	ItemArray.Clear();
	ItemArray.Add("PreliminaryBuffer");
	ItemArray.Add("UnitOfMeasureOfPreliminaryBuffer");
	ItemArray.Add("FollowUpBuffer");
	ItemArray.Add("UnitOfMeasureOfFollowUpBuffer");
	ItemArray.Add("StageDuration");
	ItemArray.Add("UnitOfMeasureOfStageDuration");
	ItemArray.Add("Continuous_");
	
	For Each TagName In ItemArray Do
		Form.Items[MatchingElements[TagName]].ReadOnly = BillOfMaterialsIsClosed;
	EndDo;
	
EndProcedure

// Fills the buffer unit in the list
//
// Parameters:
//  PlanningInterval - EnumRef.ProductionScheduleAccuracy	 - the planning interval
//  ChoiceList		 - ValueList									 - a list to fill in.
//
Procedure FillInSelectionOfBufferUnit(PlanningInterval, ChoiceList) Export

	ChoiceList.Clear();
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		ChoiceList.Add(Enums.TimeMeasureUnits.Hour);
	EndIf;
	ChoiceList.Add(Enums.TimeMeasureUnits.Day);
	
EndProcedure

// Checks the buffer unit of measurement
// 
// Parameters:
// 	Object - CatalogObject.ProductionStages
// 	Form - ClientApplicationForm
// 	ReplaceValues - Boolean
// 	ElementPrefix - String
Procedure CheckSelectionOfBufferUnit(Object, Form, ReplaceValues, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	// Pre-buffer
	ChoiceList = Items[MatchingElements.UnitOfMeasureOfPreliminaryBuffer].ChoiceList;
	If ChoiceList.FindByValue(Object.UnitOfMeasureOfPreliminaryBuffer) = Undefined 
		And ValueIsFilled(Object.UnitOfMeasureOfPreliminaryBuffer) Then
		
		If ReplaceValues Then
			
			Object.PreliminaryBuffer = 0;
			Object.UnitOfMeasureOfPreliminaryBuffer = Catalogs.ProductionStages.BasicBufferTimeUnit();
			
		ElsIf Object.PlanOperationsOfWorkCenterTypes Then
			
			DataPath = StrSplit(Items[MatchingElements.UnitOfMeasureOfPreliminaryBuffer].DataPath, ".");
			
			MessageText = NStr("vi = 'Đã chỉ ra sai đơn vị tính của bộ đệm sơ bộ.';
								|ru = 'Указана некорректная единица измерения предварительного буфера.';
								|en = 'Incorrect unit of measure of the preliminary buffer is specified.'; fa = 'Incorrect unit of measure of the preliminary buffer is specified.';
								|it = 'È stata specificata un''unità di misura per il pre-buffer non valida.';
								|pl = 'Wskazano nieprawidłową jednostkę miary buforu początkowego.';
								|tr = 'Yanlış ilk arabellek ölçü birimi belirtildi.'");
			Common.MessageToUser(
						MessageText,,
						DataPath[1],
						DataPath[0]);
		EndIf; 
		
	EndIf; 

	// The final buffer
	ChoiceList = Items[MatchingElements.UnitOfMeasureOfFollowUpBuffer].ChoiceList;
	If ChoiceList.FindByValue(Object.UnitOfMeasureOfFollowUpBuffer) = Undefined
		And ValueIsFilled(Object.UnitOfMeasureOfFollowUpBuffer) Then
		
		If ReplaceValues Then
			
			Object.FollowUpBuffer = 0;
			Object.UnitOfMeasureOfFollowUpBuffer = Catalogs.ProductionStages.BasicBufferTimeUnit();
			
		ElsIf Object.PlanOperationsOfWorkCenterTypes Then
			
			DataPath = StrSplit(Items[MatchingElements.UnitOfMeasureOfFollowUpBuffer].DataPath, ".");
			
			MessageText = NStr("vi = 'Đã chỉ ra sai đơn vị tính của bộ đệm kết thúc.';
								|ru = 'Указана некорректная единица измерения завершающего буфера.';
								|en = 'Incorrect unit of measure of the follow-up buffer is specified.'; fa = 'Incorrect unit of measure of the follow-up buffer is specified.';
								|it = 'È stata specificata un''unità di misura non valida per il buffer di terminazione.';
								|pl = 'Wskazano nieprawidłową jednostkę miary buforu końcowego.';
								|tr = 'Yanlış sonlandırma arabelleği ölçü birimi belirtildi.'");
			Common.MessageToUser(
						MessageText,,
						DataPath[1],
						DataPath[0]);
		EndIf; 
		
	EndIf; 
	
EndProcedure

// The list of default data for obtaining process parameters
// Parameters:
//  AdditionalFields - String - to add additional fields to the list of default fields
// 
// Returns:
//  String - List Of Data
Function ProcessParametersListOfData(AdditionalFields = "") Export
	
	Result = "TechnologicalProcessType,TechnologicalProcess,TechnologicalProcessFactor,ThereAreTechnologicalOperations";
	
	If Not IsBlankString(AdditionalFields) Then
		Result = Result + "," + AdditionalFields;
	EndIf;
	
	Return Result;
	
EndFunction

// The request fields are parameters of the technical process of the stage.
// 
// Parameters:
//  OneStageTable - String - Name of the stage Attributes table
//  TechnicalProcessTable - String - Name of the process data table,
//  ListOfData - String - A comma-separated list of fields to be retrieved
// 
// Returns:
//  Structure:
//  * TechnologicalProcessType - EnumRef.TechnologicalProcessTypesOfStage
//  * TechnologicalProcess - CatalogRef.TechnologicalProcesses,CatalogRef.RouteSheets
//  * TechnologicalProcessFactor - Number
//  * ThereAreTechnologicalOperations - Boolean
//  * TechnologicalProcessPresentation - String
Function RequestFieldsParametersOfTechnicalProcessOfStage(OneStageTable = "", TechnicalProcessTable = "", ListOfData = Undefined) Export
	
	If Not ValueIsFilled(ListOfData) Then
		ListOfData = ProcessParametersListOfData();
	EndIf;
	FieldsStructure = New Structure(ListOfData);
	
	StoreOperationsInBillsOfMaterials = GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	
	PackingText = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"DocumentAttributes.PackagePlan",
		"DocumentAttributes.ProductionLot.MainProductProducts");
	
	TextProcessType = "ISNULL(TechnicalProcess.TechnologicalProcessType, &Standard)";
	
	If StoreOperationsInBillsOfMaterials Then
		TextStandardTechnologicalProcess = "DocumentAttributes.BillOfMaterials";
		TextStandardOwnerOfOperations = "DocumentAttributes.Stage";
		TextCoefficientOfRouteMap = "1";
	Else
		TextStandardTechnologicalProcess = "DocumentAttributes.Stage.RouteSheet";
		TextStandardOwnerOfOperations = "DocumentAttributes.Stage.RouteSheet";
		TextCoefficientOfRouteMap =
		"CASE
		|	WHEN DocumentAttributes.Stage.RouteSheet <> VALUE(Catalog.RouteSheets.EmptyRef)
		|		THEN DocumentAttributes.Stage.RouteSheetFactor
		|	ELSE 1
		|END";
	EndIf;
	
	For Each KeyAndValue In FieldsStructure Do
		
		FieldName = KeyAndValue.Key;
		FieldText = "";
		
		If FieldName = "TechnologicalProcessType" Then
			
			FieldText = "&TextProcessType";
			
		ElsIf FieldName = "TechnologicalProcess" Then
			
			FieldText =
			"CASE
			|	WHEN NOT ISNULL(TechnicalProcess.TechnologicalProcess, UNDEFINED) IN (
			|				UNDEFINED,
			|				VALUE(Catalog.TechnologicalProcesses.EmptyRef),
			|				VALUE(Catalog.RouteSheets.EmptyRef))
			|		THEN TechnicalProcess.TechnologicalProcess
			|	WHEN &TextProcessType = &Standard
			|		THEN &TextStandardTechnologicalProcess
			|	ELSE UNDEFINED
			|END
			|";
			
		ElsIf FieldName = "TechnologicalProcessFactor" Then
			
			FieldText =
			"ISNULL(TechnicalProcess.TechnologicalProcessFactor,
			|	&TextCoefficientOfRouteMap * DocumentAttributes.NumberOfPackagesPlan * ISNULL(&PackagingFactor, 1) /
			|		CASE
			|			WHEN DocumentAttributes.QuantityPerReleaseLotUnit > 0
			|				THEN DocumentAttributes.QuantityPerReleaseLotUnit
			|			ELSE 1
			|		END)";
			
		ElsIf FieldName = "TechnologicalProcessStage" Then
			
			If StoreOperationsInBillsOfMaterials Then
				FieldText =
				"CASE
				|	WHEN &TextProcessType = &Standard
				|		THEN DocumentAttributes.Stage
				|	ELSE
				|		UNDEFINED
				|END";
			Else
				FieldText = "UNDEFINED";
			EndIf;
			
		ElsIf FieldName = "ThereAreTechnologicalOperations" Then
			
			FieldText =
			"CASE
			|	WHEN &TextProcessType = &Individual_
			|		THEN TRUE IN (
			|				SELECT TOP 1
			|					TRUE
			|				FROM
			|					InformationRegister.QueueOfProductionOperations AS T
			|				WHERE
			|					T.Stage = TechnicalProcess.Stage
			|					)
			|	ELSE TRUE IN (
			|				SELECT TOP 1
			|					TRUE
			|				FROM
			|					Catalog.ManufacturingOperations AS T
			|				WHERE
			|					NOT T.DeletionMark
			|					AND T.Owner = CASE
			|										WHEN NOT ISNULL(TechnicalProcess.TechnologicalProcess, UNDEFINED) IN (
			|													UNDEFINED,
			|													VALUE(Catalog.TechnologicalProcesses.EmptyRef),
			|													VALUE(Catalog.RouteSheets.EmptyRef))
			|											THEN TechnicalProcess.TechnologicalProcess
			|										WHEN &TextProcessType = &Standard
			|											THEN &TextStandardOwnerOfOperations
			|										ELSE UNDEFINED
			|									END
			|					)
			|END";
			
		ElsIf FieldName = "TechnologicalProcessPresentation" Then
			
			FieldText =
			"CASE
			|	WHEN &TextProcessType = VALUE(Enum.TechnologicalProcessTypesOfStage.Individual_) THEN
			|		PRESENTATION(TechnicalProcess.TechnologicalProcessType)
			|	ELSE PRESENTATION(TechnicalProcess.TechnologicalProcess)
			|END"
			
		EndIf;
		
		FieldText = StrReplace(FieldText, "&TextProcessType", TextProcessType);
		FieldText = StrReplace(FieldText, "&TextStandardTechnologicalProcess", TextStandardTechnologicalProcess);
		FieldText = StrReplace(FieldText, "&TextStandardOwnerOfOperations", TextStandardOwnerOfOperations);
		FieldText = StrReplace(FieldText, "&TextCoefficientOfRouteMap", TextCoefficientOfRouteMap);
		FieldText = StrReplace(FieldText, "&PackagingFactor", PackingText);
		
		FieldText = StrReplace(FieldText, "&Standard",    "VALUE(Enum.TechnologicalProcessTypesOfStage.Standard)");
		FieldText = StrReplace(FieldText, "&AlternateType", "VALUE(Enum.TechnologicalProcessTypesOfStage.AlternateType)");
		FieldText = StrReplace(FieldText, "&Individual_", "VALUE(Enum.TechnologicalProcessTypesOfStage.Individual_)");
		
		If Not IsBlankString(OneStageTable) Then
			FieldText = StrReplace(FieldText, "DocumentAttributes", OneStageTable);
		EndIf;
		
		If Not IsBlankString(TechnicalProcessTable) Then
			FieldText = StrReplace(FieldText, "TechnicalProcess", TechnicalProcessTable);
		EndIf;
		
		FieldsStructure.Insert(FieldName, FieldText);
		
	EndDo;
	
	Return FieldsStructure;
	
EndFunction

// Query Text parameters of the technical process of the stage.
// 
// Parameters:
//  OneStageTable - String - Name of the stage Attributes table
//  TechnicalProcessTable - String - Name of the process data table,
//  ListOfData - String - List of fields to get
// 
// Returns:
//  String
Function QueryTextParametersOfTechnicalProcessOfStage(OneStageTable = "", TechnicalProcessTable = "", ListOfData = Undefined) Export
	
	QueryTexts = New Array;
	
	For Each KeyAndValue In RequestFieldsParametersOfTechnicalProcessOfStage(OneStageTable, TechnicalProcessTable, ListOfData) Do
		
		QueryTexts.Add(StrTemplate("%1 AS %2", KeyAndValue.Value, KeyAndValue.Key));
		
	EndDo;
	
	Return StrConcat(QueryTexts, ","+Chars.LF);
	
EndFunction

#Region WorkCenterTypes

// Sets the conditional design of the list of RC types
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	TSName - String - name of the table part
// 	WorkingHoursOnlyAccordingToRegulations - Boolean
//
Procedure EstablishConditionalAppearanceTypesOfWorkCenters(Form, TSName, WorkingHoursOnlyAccordingToRegulations = True) Export

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	// Prohibition of unchecking Use for the type of RC
	#Region ProhibitionToUse
	
	If Items.Find(TSName + "Use") <> Undefined Then
		
		Item = ConditionalAppearance.Items.Add();
		
		FormField    = Items[TSName + "Use"]; // FormField
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(TSName + ".Use");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;

		Item.Appearance.SetParameterValue("ReadOnly", True);
		
	EndIf;
	
	#EndRegion

	// Allocation of an alternative type of RC
	#Region AlternativeVRCColor
	
	Item = ConditionalAppearance.Items.Add();
	
	FormField    = Items[TSName + "WorkCenterType"]; // FormField
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormField.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(TSName + ".AlternateType");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfAlternateWorkCenterType);
	
	#EndRegion
	
	// Setup options
	#Region SetupOptions
	
	If Items.Find(TSName + "SetupSettings") <> Undefined Then
		
		Item = ConditionalAppearance.Items.Add();
		
		FormField    = Items[TSName + "SetupSettings"]; // FormField
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(TSName + ".SetupOptionIsUsed");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
														|ru = '<не используется>';
														|en = '<not used>'; fa = '<استفاده نمی‌شود>';
														|it = '<non viene utilizzato>';
														|pl = '<nie używa się>';
														|tr = '<kullanılmayan>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
	
	EndIf;
	
	#EndRegion
	
	// Forbidding editing of working hours if synchronous loading is used
	#Region WorkTimeOnSynchronousLoad
	
	If WorkingHoursOnlyAccordingToRegulations Then
		Item = ConditionalAppearance.Items.Add();
		
		FormField    = Items[TSName + "OperationTime"]; // FormField
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		FormField    = Items[TSName + "UnitOfMeasure"]; // FormField
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(FormField.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(TSName + ".SynchronousLoad");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("ReadOnly", True);
	EndIf;
	
	#EndRegion
	
	// The mark of the filled in for the Upload field
	#Region Loading_MarkBlank
	
	If Items.Find(TSName + "Load") <> Undefined Then
		
		Item = ConditionalAppearance.Items.Add();
	
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(TSName + "Load");
		
		If Items.Find(TSName + "LoadStandard") <> Undefined Then
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(TSName + "LoadStandard");
		EndIf;
		
		If Items.Find(TSName + "MaximumLoad") <> Undefined Then
			ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(TSName + "MaximumLoad");
		EndIf;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(TSName + ".ParallelLoad");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
														|ru = '<не используется>';
														|en = '<not used>'; fa = '<استفاده نمی‌شود>';
														|it = '<non viene utilizzato>';
														|pl = '<nie używa się>';
														|tr = '<kullanılmayan>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
			
	EndIf;
	
	#EndRegion
	
EndProcedure

// Sets additional conditional design of the types of work centers during synchronous loading
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	TSName - String
// 	ObjectName - String
// 	ElementPrefix - String
Procedure SetConditionalAppearanceOfBankingDetailsForSynchronousUploading(Form, TSName, ObjectName = "Object", ElementPrefix = "") Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	// We hide the editing of the working time if synchronous loading is used, but the setup option is not selected.
	#Region RunningTimeForSynchronousLoading_Hide
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName+"OperationTime"].Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName+"UnitOfMeasure"].Name);
	
	FilterOrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	FilterAndGroup = FilterOrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterAndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	AddLayoutSelectionSynchronousLoadingSetupOptionNotFilledIn(FilterAndGroup, TSName);
	
	FilterAndGroup = FilterOrGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterAndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	AddSelectionAndSimultaneousLoading(FilterAndGroup, ObjectName, TSName, MatchingElements);
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	// Hiding the label intended for synchronous loading
	#Region TypesOfWorkCentersWorkingTimeWithSynchronousLoading_Hide
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName+"WorkTimeOnSynchronousLoad"].Name);
		
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
		
	FilterNotGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterNotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
		
	AddLayoutSelectionSynchronousLoadingSetupOptionNotFilledIn(FilterNotGroup, TSName);
		
	FilterNotGroup = FilterGroup.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterNotGroup.GroupType = DataCompositionFilterItemsGroupType.NotGroup;
		
	AddSelectionAndSimultaneousLoading(FilterNotGroup, ObjectName, TSName, MatchingElements);
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	// We show the inscription intended for synchronous loading if the setup option is not selected.
	#Region TypesOfWorkCentersOperatingTimeWithSynchronousLoading_Show
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName+"WorkTimeOnSynchronousLoad"].Name);

	AddLayoutSelectionSynchronousLoadingSetupOptionNotFilledIn(Item.Filter, TSName);
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<theo phương án gỡ rối>';
													|ru = '<по варианту наладки>';
													|en = '<by equipment setup settings>'; fa = '<by equipment setup settings>';
													|it = '<in base all''opzione di configurazione>';
													|pl = '<wg wariantu konfiguracji>';
													|tr = '<ekipman kurulum ayarlarına göre>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	#EndRegion
	
	// We show the inscription with the simultaneous order of operation if the time is determined by synchronous types of RC.
	#Region TypesOfWorkCentersOperatingTimeWithSynchronousSimultaneousLoading_Show
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[TSName+"WorkTimeOnSynchronousLoad"].Name);
		
	AddSelectionAndSimultaneousLoading(Item.Filter, ObjectName, TSName, MatchingElements);
		
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<theo dạng nguồn lực sản xuất có đồng bộ kết nhập>';
													|ru = '<по ВРЦ с синхронной загрузкой>';
													|en = '<by work center type with synchronous load>'; fa = '<by work center type with synchronous load>';
													|it = '<in base al tipo di Centro di lavoro con carico sincronizzato>';
													|pl = '<wg tymczasowych centrum pracowniczych z synchronicznym pobieraniem>';
													|tr = '<senkronik çalışma yüklü İMT doğrultusunda>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	#EndRegion
	
EndProcedure

Procedure FillInTreeOfTypesOfWorkCenters(WorkCenterTypes, AlternateWorkCenterTypes, AllKindsOfWorkCenters, FillInSynchronousDownloadTime) Export
	
	ListOfTypesOfWorkCenters = New Array;
	ListOfSetupOptions = New Array;
	
	CollectionTypesOfRC = AllKindsOfWorkCenters.GetItems();	
	CollectionTypesOfRC.Clear();

	For Each RowViewRC In WorkCenterTypes Do
		NewTypeOfRC = CollectionTypesOfRC.Add();
		FillPropertyValues(NewTypeOfRC, RowViewRC);
		
		If ValueIsFilled(NewTypeOfRC.WorkCenterType) Then
			ListOfTypesOfWorkCenters.Add(NewTypeOfRC.WorkCenterType);
		EndIf; 
		If ValueIsFilled(NewTypeOfRC.SetupSettings) Then
			ListOfSetupOptions.Add(NewTypeOfRC.SetupSettings);
		EndIf; 
		
		CollectionAlternativeTypesOfRC = NewTypeOfRC.GetItems();
		TheStructureOfTheSearch = New Structure("LinkKeyWorkCenterTypes", RowViewRC.ConnectionKey);
		StringsList = AlternateWorkCenterTypes.FindRows(TheStructureOfTheSearch);
		NewTypeOfRC.ChangeIsAvailableUse = (StringsList.Count() <> 0);
		For Each StringAlternativeViewOfRC In StringsList Do
			NewAlternativeTypeOfRC = CollectionAlternativeTypesOfRC.Add();
			FillPropertyValues(NewAlternativeTypeOfRC, StringAlternativeViewOfRC);
			NewAlternativeTypeOfRC.AlternateType = True;
			NewAlternativeTypeOfRC.ChangeIsAvailableUse = True;
			
			If ValueIsFilled(NewAlternativeTypeOfRC.WorkCenterType) Then
				ListOfTypesOfWorkCenters.Add(NewAlternativeTypeOfRC.WorkCenterType);
			EndIf; 
			If ValueIsFilled(NewAlternativeTypeOfRC.SetupSettings) Then
				ListOfSetupOptions.Add(NewAlternativeTypeOfRC.SetupSettings);
			EndIf; 
		EndDo;
	EndDo;
	
	ValuesOfDetailsOfRCTypes =
		Common.ObjectsAttributesValues(
			ListOfTypesOfWorkCenters, 
			"SetupSettingsAreUsed,ParallelLoad,ImportOption,OperationTime,UnitOfMeasure,MaximumLoad");
	
	If ListOfSetupOptions.Count() <> 0 Then
		SettingOptionsDetailsValues = Common.ObjectsAttributesValues(
												ListOfSetupOptions, 
												"OperationTime,UnitOfMeasure");
	Else
		SettingOptionsDetailsValues = New Map;
	EndIf;
	
	For Each RowViewRC In CollectionTypesOfRC Do
		
		DetailsOfRCType = ValuesOfDetailsOfRCTypes.Get(RowViewRC.WorkCenterType);
		DetailsOfSetupOption = SettingOptionsDetailsValues.Get(RowViewRC.SetupSettings);
		FillInServiceDetailsInLineOfTypesOfRC(
			DetailsOfRCType,
			DetailsOfSetupOption,
			False,
			RowViewRC,
			FillInSynchronousDownloadTime);
		
		CollectionAlternativeTypesOfRC = RowViewRC.GetItems();
		For Each StringAlternativeViewOfRC In CollectionAlternativeTypesOfRC Do
			
			DetailsOfRCType = ValuesOfDetailsOfRCTypes.Get(StringAlternativeViewOfRC.WorkCenterType);
			DetailsOfSetupOption = SettingOptionsDetailsValues.Get(StringAlternativeViewOfRC.SetupSettings);
			FillInServiceDetailsInLineOfTypesOfRC(
				DetailsOfRCType,
				DetailsOfSetupOption,
				False,
				StringAlternativeViewOfRC,
				FillInSynchronousDownloadTime);
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure SaveTypesOfWorkCenters(AllKindsOfWorkCenters, SchedulingOfWorkCenters, WorkCenterTypes, AlternateWorkCenterTypes) Export

	WorkCenterTypes.Clear();
	AlternateWorkCenterTypes.Clear();
	
	If Not SchedulingOfWorkCenters Then
		Return;
	EndIf;
	
	EmptyKey = New UUID("00000000-0000-0000-0000-000000000000");
	
	MainTypesOfWorkCenters = AllKindsOfWorkCenters.GetItems();
	For Each RowMainViewOfRC In MainTypesOfWorkCenters Do
		NewTypeOfRC = WorkCenterTypes.Add();
		FillPropertyValues(NewTypeOfRC, RowMainViewOfRC);
		If NewTypeOfRC.ConnectionKey = EmptyKey Then
			NewTypeOfRC.ConnectionKey = New UUID;
		EndIf;
		
		AlternativeTypesOfRC = RowMainViewOfRC.GetItems();
		For Each StringAlternativeViewOfRC In AlternativeTypesOfRC Do
			NewAlternativeTypeOfRC = AlternateWorkCenterTypes.Add();
			FillPropertyValues(NewAlternativeTypeOfRC, StringAlternativeViewOfRC);
			NewAlternativeTypeOfRC.LinkKeyWorkCenterTypes = NewTypeOfRC.ConnectionKey;
		EndDo; 
	EndDo; 
	
EndProcedure

Procedure FillInServiceDetailsInLineOfTypesOfRC(DetailsOfRCType, DetailsOfSetupOption, GetAttributes, RowViewRC, FillInSynchronousDownloadTime = True) Export

	If GetAttributes Then
		If ValueIsFilled(RowViewRC.WorkCenterType) Then
			DetailsOfRCType = Common.ObjectAttributesValues(
													RowViewRC.WorkCenterType, 
													"SetupSettingsAreUsed,ParallelLoad,
													|ImportOption,OperationTime,UnitOfMeasure,
													|MaximumLoad");
		Else
			DetailsOfRCType = Undefined;
		EndIf;

		If ValueIsFilled(RowViewRC.SetupSettings) Then
			DetailsOfSetupOption = Common.ObjectAttributesValues(
													RowViewRC.SetupSettings, 
													"OperationTime,UnitOfMeasure");
		Else
			DetailsOfSetupOption = Undefined;
		EndIf;
	EndIf; 
	
	RowViewRC.SetupOptionIsUsed = False;
	RowViewRC.ParallelLoad = False;
	RowViewRC.SynchronousLoad = False;
	
	If DetailsOfRCType = Undefined Then
		RowViewRC.OperationTime = 0;
		RowViewRC.UnitOfMeasure = Enums.TimeMeasureUnits.EmptyRef();
		Return;
	EndIf;
	
	SetupSettingsAreUsed = DetailsOfRCType.SetupSettingsAreUsed;
	RowViewRC.SetupOptionIsUsed = (SetupSettingsAreUsed = True);
	
	RowViewRC.ParallelLoad = DetailsOfRCType.ParallelLoad;
	
	If DetailsOfRCType.ParallelLoad
		And DetailsOfRCType.ImportOption = Enums.WorkCenterLoadOptions.Synchronous Then
		
		If FillInSynchronousDownloadTime Then
			
			If SetupSettingsAreUsed Then
				If DetailsOfSetupOption <> Undefined Then
					OperationTime = DetailsOfSetupOption.OperationTime;
					UnitOfMeasure = DetailsOfSetupOption.UnitOfMeasure;
				Else
					OperationTime = 0;
					UnitOfMeasure = Enums.TimeMeasureUnits.EmptyRef();
				EndIf; 
			Else
				OperationTime = DetailsOfRCType.OperationTime;
				UnitOfMeasure = DetailsOfRCType.UnitOfMeasure;
			EndIf;
			RowViewRC.OperationTime = OperationTime;
			RowViewRC.UnitOfMeasure = UnitOfMeasure;
			
		EndIf;
		
		RowViewRC.SynchronousLoad = True;
		
	EndIf;
	
	AdditionalAttributes = New Structure;
	
	AdditionalAttributes.Insert("MaximumLoad");
	DetailsOfRCType.Property("MaximumLoad", AdditionalAttributes.MaximumLoad);
	
	If RowViewRC.SynchronousLoad Then
		AdditionalAttributes.Insert("CalculationByFormula", False);
		AdditionalAttributes.Insert("QuantityCalculationAlgorithm", "");
	EndIf;
	
	FillPropertyValues(RowViewRC, AdditionalAttributes);
	
EndProcedure

Procedure FillInTheTypesOfWorkCenters(Object, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad) Export
	
	ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
		Object.WorkCenterTypes,
		False,
		True,
		Object.SelectionByProperties);
		
	ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
		Object.AlternateWorkCenterTypes,
		False,
		True,
		Object.SelectionByProperties);
	
	FillInTreeOfTypesOfWorkCenters(
		Object.WorkCenterTypes,
		Object.AlternateWorkCenterTypes,
		WorkCenterTypes,
		True);
	
	ProductionProcessEditorClientServer.CalculateServiceSignsOfLoadingVRC(
		WorkCenterTypes,
		ThereIsParallelDownload,
		ThereIsSynchronousLoad);
	
EndProcedure

Procedure CheckAllKindsOfWorkCenters(Object, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad) Export
	
	SaveTypesOfWorkCenters(
		WorkCenterTypes,
		Object.PlanOperationsOfWorkCenterTypes,
		Object.WorkCenterTypes,
		Object.AlternateWorkCenterTypes);
	
	ProductDataManagement.CheckComplianceOfDetailsWithDivision(Object);
	
	FillInTheTypesOfWorkCenters(Object, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad);
	
EndProcedure

Procedure CalculateStageDuration(Object, WorkCenterTypes) Export
	
	CatalogObject = FormDataToValue(Object, Type("CatalogObject.ProductionStages"));
	
	SaveTypesOfWorkCenters(
		WorkCenterTypes,
		CatalogObject.PlanOperationsOfWorkCenterTypes,
		CatalogObject.WorkCenterTypes,
		CatalogObject.AlternateWorkCenterTypes);
	
	CatalogObject.FillInUnitOfMeasurementAndDurationOfBBVStage();
	
	FillPropertyValues(Object, CatalogObject, "UnitOfMeasureOfStageDuration, StageDuration");
	
EndProcedure

Procedure FillInWorkCenterKindsUsingAnOperationsSheet(
	Object, Form, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad, ElementPrefix = "") Export
	
	Catalogs.ProductionStages.FillInWorkCenterKindsUsingAnOperationsSheet(Object);
	CheckSelectionOfBufferUnit(Object, Form, True, ElementPrefix);

	// By default, we use the main types of RC
	For Each RowMainViewOfRC In Object.WorkCenterTypes Do
		RowMainViewOfRC.Use = True;
	EndDo;
	
	FillInTheTypesOfWorkCenters(Object, WorkCenterTypes, ThereIsParallelDownload, ThereIsSynchronousLoad);
	
EndProcedure

Function FillInTypesOfWorkCentersForOperationsConstructor() Export
	
	OperationData_  = New ValueTable;
	
	OperationData_.Columns.Add("FilledIn",         New TypeDescription("Boolean"));
	OperationData_.Columns.Add("OperationNumber",     New TypeDescription("Number"));
	OperationData_.Columns.Add("Ref",            New TypeDescription("CatalogRef.ManufacturingOperations"));
	OperationData_.Columns.Add("WorkCenter",      New TypeDescription("CatalogRef.WorkCenters,CatalogRef.WorkCenterTypes"));
	OperationData_.Columns.Add("SetupSettings",    New TypeDescription("CatalogRef.SetupOptions"));
	OperationData_.Columns.Add("TimePerPiece",      New TypeDescription("Number"));
	OperationData_.Columns.Add("TimePerPieceUnitOfMeasure", New TypeDescription("EnumRef.TimeMeasureUnits"));
	OperationData_.Columns.Add("SetupTime",           New TypeDescription("Number"));
	OperationData_.Columns.Add("SetupTimeUnitOfMeasure",      New TypeDescription("EnumRef.TimeMeasureUnits"));
	OperationData_.Columns.Add("Load",          New TypeDescription("Number"));
	
	OperationData_.Columns.Add("ContainsTechnologicalProcess",      New TypeDescription("Boolean"));
	OperationData_.Columns.Add("TechnologicalProcess",              New TypeDescription("CatalogRef.TechnologicalProcesses"));
	OperationData_.Columns.Add("TechnologicalProcessFactor", New TypeDescription("Number"));
	
	Return OperationData_;
	
EndFunction

Function FillInTypesOfWorkCentersForOperations(StageObject, OperationData_) Export
	
	QueryText = "
	|SELECT
	|	OperationData_.FilledIn                           AS FilledIn,
	|	OperationData_.OperationNumber                       AS OperationNumber,
	|	OperationData_.Ref                              AS Ref,
	|	OperationData_.WorkCenter                        AS WorkCenter,
	|	OperationData_.SetupSettings                      AS SetupSettings,
	|	OperationData_.TimePerPiece                        AS TimePerPiece,
	|	OperationData_.TimePerPieceUnitOfMeasure                   AS TimePerPieceUnitOfMeasure,
	|	OperationData_.SetupTime                             AS SetupTime,
	|	OperationData_.SetupTimeUnitOfMeasure                        AS SetupTimeUnitOfMeasure,
	|	OperationData_.Load                            AS Load,
	|	OperationData_.ContainsTechnologicalProcess      AS ContainsTechnologicalProcess,
	|	OperationData_.TechnologicalProcess              AS TechnologicalProcess,
	|	OperationData_.TechnologicalProcessFactor AS TechnologicalProcessFactor
	|
	|INTO TTTransactionData
	|FROM
	|	&OperationData_ AS OperationData_
	|;
	|
	|SELECT
	|	CASE
	|		WHEN NestedQuery.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN NestedQuery.WorkCenter
	|		ELSE CAST(NestedQuery.WorkCenter AS Catalog.WorkCenters).WorkCenterType
	|	END                                               AS WorkCenterType,
	|	NestedQuery.SetupSettings                      AS SetupSettings,
	|	NestedQuery.Load                            AS Load,
	|	NestedQuery.ZoomRatio                         AS ZoomRatio,
	|	NestedQuery.OperationNumber                       AS OperationNumber,
	|	NestedQuery.TechnologicalProcess              AS TechnologicalProcess,
	|	NestedQuery.TechnologicalProcessOperationNumber AS TechnologicalProcessOperationNumber,
	|	&TextDetailsForCalculatingOperationExecutionTime
	|
	|INTO TTDataOnWorkCenters
	|FROM (
	|		SELECT
	|			OperationData_.OperationNumber                                                                 AS OperationNumber,
	|			ISNULL(TechnologicalProcessOfOperation.Owner,          UNDEFINED)                     AS TechnologicalProcess,
	|			ISNULL(TechnologicalProcessOfOperation.OperationNumber,     0)                                AS TechnologicalProcessOperationNumber,
	|			ISNULL(TechnologicalProcessOfOperation.WorkCenter,      OperationData_.WorkCenter)      AS WorkCenter,
	|			ISNULL(TechnologicalProcessOfOperation.SetupSettings,    OperationData_.SetupSettings)    AS SetupSettings,
	|			ISNULL(TechnologicalProcessOfOperation.TimePerPiece,      OperationData_.TimePerPiece)      AS TimePerPiece,
	|			ISNULL(TechnologicalProcessOfOperation.TimePerPieceUnitOfMeasure, OperationData_.TimePerPieceUnitOfMeasure) AS TimePerPieceUnitOfMeasure,
	|			ISNULL(TechnologicalProcessOfOperation.SetupTime,           OperationData_.SetupTime)           AS SetupTime,
	|			ISNULL(TechnologicalProcessOfOperation.SetupTimeUnitOfMeasure,      OperationData_.SetupTimeUnitOfMeasure)      AS SetupTimeUnitOfMeasure,
	|			ISNULL(TechnologicalProcessOfOperation.Load,          OperationData_.Load)          AS Load,
	|			CASE WHEN OperationData_.ContainsTechnologicalProcess
	|				THEN OperationData_.TechnologicalProcessFactor
	|			ELSE 1 END                                                                                AS ZoomRatio
	|		FROM
	|			TTTransactionData AS OperationData_
	|				LEFT JOIN Catalog.ManufacturingOperations AS TechnologicalProcessOfOperation
	|				ON OperationData_.ContainsTechnologicalProcess
	|					AND OperationData_.TechnologicalProcess = TechnologicalProcessOfOperation.Owner
	|					AND NOT TechnologicalProcessOfOperation.DeletionMark
	|		WHERE
	|			OperationData_.FilledIn
	|
	|		UNION ALL
	|
	|		SELECT
	|			OperationData_.OperationNumber,
	|			ISNULL(TechnologicalProcessOfOperation.Owner,          UNDEFINED),
	|			ISNULL(TechnologicalProcessOfOperation.OperationNumber,     0),
	|			ISNULL(TechnologicalProcessOfOperation.WorkCenter,      TransactionDetails.WorkCenter),
	|			ISNULL(TechnologicalProcessOfOperation.SetupSettings,    TransactionDetails.SetupSettings),
	|			ISNULL(TechnologicalProcessOfOperation.TimePerPiece,      TransactionDetails.TimePerPiece),
	|			ISNULL(TechnologicalProcessOfOperation.TimePerPieceUnitOfMeasure, TransactionDetails.TimePerPieceUnitOfMeasure),
	|			ISNULL(TechnologicalProcessOfOperation.SetupTime,           TransactionDetails.SetupTime),
	|			ISNULL(TechnologicalProcessOfOperation.SetupTimeUnitOfMeasure,      TransactionDetails.SetupTimeUnitOfMeasure),
	|			ISNULL(TechnologicalProcessOfOperation.Load,          TransactionDetails.Load),
	|			CASE WHEN TransactionDetails.ContainsTechnologicalProcess
	|				THEN TransactionDetails.TechnologicalProcessFactor
	|			ELSE 1 END
	|		FROM
	|			TTTransactionData AS OperationData_
	|				LEFT JOIN Catalog.ManufacturingOperations AS TransactionDetails
	|				ON OperationData_.Ref = TransactionDetails.Ref
	|				LEFT JOIN Catalog.ManufacturingOperations AS TechnologicalProcessOfOperation
	|				ON TransactionDetails.ContainsTechnologicalProcess
	|					AND TransactionDetails.TechnologicalProcess = TechnologicalProcessOfOperation.Owner
	|					AND NOT TechnologicalProcessOfOperation.DeletionMark
	|		WHERE
	|			NOT OperationData_.FilledIn
	|	
	|	) AS NestedQuery
	|
	|WHERE
	|	 (CASE
	|		WHEN NestedQuery.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN CAST(NestedQuery.WorkCenter AS Catalog.WorkCenterTypes).UseAvailabilityAccordingToSchedule
	|		WHEN NestedQuery.WorkCenter REFS Catalog.WorkCenters
	|			THEN CAST(NestedQuery.WorkCenter AS Catalog.WorkCenters).WorkCenterType.UseAvailabilityAccordingToSchedule
	|		ELSE FALSE
	|	END)
	|	AND (CASE
	|		WHEN NestedQuery.WorkCenter REFS Catalog.WorkCenterTypes
	|			THEN CAST(NestedQuery.WorkCenter AS Catalog.WorkCenterTypes).Department
	|		ELSE CAST(NestedQuery.WorkCenter AS Catalog.WorkCenters).WorkCenterType.Department
	|	END) = &Department
	|;
	|
	|SELECT
	|	T.*
	|FROM
	|	TTDataOnWorkCenters AS T
	|
	|ORDER BY
	|	T.OperationNumber,
	|	T.TechnologicalProcessOperationNumber
	|;
	|
	|SELECT
	|	T.OperationNumber                                                                                                 AS OperationNumber,
	|	T.TechnologicalProcess                                                                                        AS TechnologicalProcess,
	|	COUNT(T.TechnologicalProcessOperationNumber) = COUNT(DISTINCT T.TechnologicalProcessOperationNumber) AS Sequentially
	|FROM
	|	TTDataOnWorkCenters AS T
	|WHERE
	|	T.TechnologicalProcess <> UNDEFINED
	|GROUP BY
	|	T.OperationNumber,
	|	T.TechnologicalProcess
	|";
	
	QueryText = StrReplace(
		QueryText,
		"&TextDetailsForCalculatingOperationExecutionTime",
		Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("NestedQuery"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("OperationData_",   OperationData_);
	Query.SetParameter("Department",    StageObject.Department);
	
	QueryResults    = Query.ExecuteBatch();
	VRCSample           = QueryResults[2].Select();
	ResultTechnicalProcesses = QueryResults[3].Unload();
	
	StageObject.WorkCenterTypes.Clear();
	StageObject.AlternateWorkCenterTypes.Clear();
	StageObject.OperatingProcedureOfWorkCenterTypes = Undefined;
	
	NumbersArray = OperationData_.UnloadColumn("OperationNumber");
	
	If VRCSample.Count() > 0 Then
	
		If NumbersArray.Count() = CommonClientServer.CollapseArray(NumbersArray).Count()
			And ResultTechnicalProcesses.Find(False, "Sequentially") = Undefined Then
			StageObject.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially;
		Else
			StageObject.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("WorkCenterType,SetupSettings");
		ListOfTypesOfWorkCenters = StageObject.WorkCenterTypes;
		While VRCSample.Next() Do
			
			FillPropertyValues(TheStructureOfTheSearch, VRCSample);
			StringsList = ListOfTypesOfWorkCenters.FindRows(TheStructureOfTheSearch);
			
			If StringsList.Count() = 0 Then
				RowViewRC = ListOfTypesOfWorkCenters.Add();
				RowViewRC.ConnectionKey         = New UUID;
				RowViewRC.WorkCenterType = VRCSample.WorkCenterType;
				RowViewRC.SetupSettings    = VRCSample.SetupSettings;
				RowViewRC.UnitOfMeasure  = VRCSample.TimePerPieceUnitOfMeasure;
				ProductionProcessEditorClientServer.WhenEnteringNewLineOfTypesOfWorkCenters(RowViewRC, False);
			Else
				RowViewRC = StringsList[0];
			EndIf;
			
			If StageObject.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially Then
				
				If VRCSample.TimePerPieceUnitOfMeasure = RowViewRC.UnitOfMeasure Then
					OperationTime = VRCSample.TimePerPiece;
				Else
					OperationTime = ProductionPlanningClientServer.GetTimeInUnit(
																ProductionPlanningClientServer.GetTimeInSeconds(
																			VRCSample.TimePerPiece,
																			VRCSample.TimePerPieceUnitOfMeasure),
																RowViewRC.UnitOfMeasure);
				EndIf;
				
				RowViewRC.OperationTime = RowViewRC.OperationTime + OperationTime * VRCSample.ZoomRatio;
				RowViewRC.Load    = RowViewRC.Load + VRCSample.Load * VRCSample.ZoomRatio;
				
			EndIf;
			
		EndDo;
	
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region TechnologicalOperation

// Processing the choice of WHO
// 
// Parameters:
//  Object - CatalogObject.ManufacturingOperations
//  Form - ClientApplicationForm
//  ValueSelected - CatalogRef.ManufacturingOperationClassifier
//  ElementPrefix - String
Procedure ClassifierOfTechnologicalOperationsChoiceProcessing(Object, Form, ValueSelected, ElementPrefix = "") Export
	
	DetailsOfWHO = ValuesOfDetailsOfOperationsForWHO(Object, Form, ValueSelected, , ElementPrefix);
	
	FillPropertyValues(Object, DetailsOfWHO);
	
	If DetailsOfWHO.Property("OperationKind") Then
		OperationKindOnChange(Object, Form, ElementPrefix);
	EndIf;
	
EndProcedure

// Processing the choice of WHO
// 
// Parameters:
//	Object - CatalogObject.ManufacturingOperations
//	Form - ClientApplicationForm
//	ValueSelected - CatalogRef.ManufacturingOperationClassifier
//	NewOperation - Boolean
//	ElementPrefix - String
//  
// Returns:
// 	Structure - From:
//		* CLASSIFIEROFTECHNOLOGICALOPERATIONS - CatalogRef.ManufacturingOperationClassifier - BillOfMaterials
//		* Description - String -
//		* OperationKind - CatalogRef.TechnologicalOperationKinds
Function ValuesOfDetailsOfOperationsForWHO(Object, Form, ValueSelected, NewOperation = False, ElementPrefix = "") Export
	
	Result = New Structure;
	Result.Insert("CLASSIFIEROFTECHNOLOGICALOPERATIONS", ValueSelected);
	
	If ValueIsFilled(ValueSelected) Then
		
		ItemKind = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
		
		MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
		
		ReferencesArrray = New Array;
		ReferencesArrray.Add(Object.ClassifierOfTechnologicalOperations);
		ReferencesArrray.Add(ValueSelected);
		
		AttributesValues = Common.ObjectsAttributesValues(ReferencesArrray, "Description,OperationKind");
		
		If NewOperation
			Or Form.CurrentItem = Form.Items[MatchingElements.Description]
			Or ValueIsFilled(Object.ClassifierOfTechnologicalOperations)
				And Object.Description = AttributesValues[Object.ClassifierOfTechnologicalOperations].Description
			Or Not ValueIsFilled(Object.Description)
			Or Object.Description = ProductionProcessEditorClientServer.NameOfNewItem(ItemKind, Object.OperationNumber) Then
			
			Result.Insert("Description", AttributesValues[ValueSelected].Description);
			
		EndIf;
		
		If NewOperation
			Or ValueIsFilled(AttributesValues[ValueSelected].OperationKind)
				And Object.OperationKind <> AttributesValues[ValueSelected].OperationKind Then
			
			Result.Insert("OperationKind", AttributesValues[ValueSelected].OperationKind);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Handler for changing a Section in an operation
// 
// Parameters:
// 	The object is a reference object.Technological Operations
// 	Form - formaclient applications
// 	Element Prefix - String

Procedure ProductionAreaOnChange(Object, Form, ElementPrefix = "") Export
	
	ConfigureSettingsForSelectingWorkCenters(Object, Form, Undefined, ElementPrefix, "ProductionArea");
	
	If Not Object.ProductionArea = Catalogs.ProductionSites.EmptyRef() 
		And Type("CatalogRef.WorkCenters") = TypeOf(Object.WorkCenter) Then
		Object.WorkCenter = Catalogs.WorkCenters.EmptyRef();
	EndIf;
	
EndProcedure

// Handler for changing the work center in an operation
// 
// Parameters:
// 	Object - CatalogObject.ManufacturingOperations
// 	Form - ClientApplicationForm
// 	ElementPrefix - String
Procedure WorkCenterOnChange(Object, Form, ElementPrefix = "") Export
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	CheckCorrectSetupOption(Object);
	
	ReadDetailsOfWorkCenter(Object, Form,, MatchingElements);
	
	ConfigureVisibilityAccessibilityByRCDetails(Form, MatchingElements);
	
	Items = Form.Items;
	
	Items[MatchingElements.ProductionArea].InputHint = 
		PlotPresentation(Object, Items[MatchingElements.ProductionArea].Visible);
	
	If Not Items[MatchingElements.Load].Visible Then
		Object.Load = 0;
	EndIf;
	
	If Not Items[MatchingElements.TimePerPiece].Visible Then
		Object.TimePerPiece = 0;
	EndIf;
	
	If Not Items[MatchingElements.SetupTime].Visible Then
		Object.SetupTime = 0;
	EndIf;
	
EndProcedure

Procedure SetupSettingsOnChange(Object, Form, ElementPrefix = "") Export
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	DetailsDependOnSetupOption = Form[MatchingElements.SynchronousLoad]
											And Form[MatchingElements.SetupSettingsAreUsed];
	
	If DetailsDependOnSetupOption Then
		ReadDetailsOfSetupOption(Object, Form, MatchingElements);
	EndIf;
	
EndProcedure

Procedure ReadDetailsOfWorkCenter(Object, Form, ElementPrefix = "", MatchingElements = Undefined) Export
	
	If MatchingElements = Undefined Then
		MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	EndIf;
	
	AttributesValues = Catalogs.WorkCenterTypes.ValuesForWorkCenterTypeDetails(
		Object.WorkCenter, Object.SetupSettings);
	
	For Each KeyAndValue In StructureOfCorrespondenceOfElementsToDetailsOfWorkCenter(MatchingElements) Do
		If AttributesValues.Property(KeyAndValue.Value) Then
			Form[KeyAndValue.Key] = AttributesValues[KeyAndValue.Value];
		EndIf;
	EndDo;
	
	Form[MatchingElements.SynchronousLoad] =
		(AttributesValues.ImportOption = Enums.WorkCenterLoadOptions.Synchronous);
	
EndProcedure

// Adjusts the parameters of the selection of the site of technological operations
// 
// Parameters:
//  Object - CatalogObject.ManufacturingOperations - Object
//  Form - ClientApplicationForm - Form
// 	Department - CatalogRef.BusinessStructure
//  ElementPrefix - String - element prefix
Procedure ConfigureSiteSelectionParameters(Object, Form, Department = Undefined, ElementPrefix = "") Export
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	If Department = Undefined Then
		Department = Common.ObjectAttributeValue(Object.Owner, "Department");
	EndIf;
	
	ParameterName = "Filter.Owner";
	
	AdjustSelectionParameters(ParameterName, Department, Form.Items, MatchingElements.ProductionArea);
		
EndProcedure

// Configures the parameters for selecting the work centers of the technological operation
// 
// Parameters:
// 	Object - CatalogObject.ManufacturingOperations
// 	Form - ClientApplicationForm
// 	Department - CatalogRef.BusinessStructure
// 	ElementPrefix - String
// 	ParametersList - String
Procedure ConfigureSettingsForSelectingWorkCenters(Object, Form, Department = Undefined, ElementPrefix = "", ParametersList = "") Export

	Initialize = IsBlankString(ParametersList);
	AttributesStructure1 = New Structure(ParametersList);
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	If Initialize Or AttributesStructure1.Property("Department") Then
		
		ParameterName = "Filter.Department";

		If Department = Undefined Then
			Department = Common.ObjectAttributeValue(Object.Owner, "Department");
		EndIf;

		AdjustSelectionParameters(ParameterName, Department, Form.Items, MatchingElements.WorkCenter);
		AdjustSelectionParameters(ParameterName, Department, Form.Items, MatchingElements.AuxiliaryWorkCentersWorkCenter);

	EndIf;

	If Initialize Or AttributesStructure1.Property("ProductionArea") Then
		
		ParameterName = "Filter.ProductionArea";

		ProductionArea = Object.ProductionArea;
		
		If ProductionArea = Catalogs.ProductionSites.EmptyRef() Then
			ProductionArea = Undefined;
		EndIf;
			
		AdjustSelectionParameters(ParameterName, ProductionArea, Form.Items, MatchingElements.WorkCenter);
		AdjustSelectionParameters(ParameterName, ProductionArea, Form.Items, MatchingElements.AuxiliaryWorkCentersWorkCenter);
		
	EndIf;

EndProcedure

Function DetermineAvailabilityOfOperationElements(OwnerStatus) Export
	
	Return (OwnerStatus = Enums.StatusesOfRouteSheets.UnderDevelopment
				Or OwnerStatus = Enums.BOMStatuses.UnderDevelopment
				Or OwnerStatus = Enums.TechnologicalProcessStatuses.UnderDevelopment);
	
EndFunction

// Configures the operation elements
// 
// Parameters:
// 	Object - CatalogObject.ManufacturingOperations
// 	Form - ClientApplicationForm
// 	DivisionParameters - Structure
// 	ElementPrefix - String
Procedure ConfigureVisibilityAvailabilityOfOperationElements(Object, Form, DivisionParameters = Undefined, ElementPrefix = "") Export
	
	Items = Form.Items;
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	ItemsAvailability        = Form[MatchingElements.ItemsAvailability];
	SetupSettingsAreUsed = Form[MatchingElements.SetupSettingsAreUsed];
	
	If Not Form.ReadOnly Then
		
		ItemArray = New Array;
		ItemArray.Add("OperationNumber");
		ItemArray.Add("NextOperation");
		ItemArray.Add("ProductionArea");
		ItemArray.Add("WorkCenter");
		ItemArray.Add("TimePerPiece");
		ItemArray.Add("TimePerPieceUnitOfMeasure");
		ItemArray.Add("SetupTime");
		ItemArray.Add("SetupTimeUnitOfMeasure");
		ItemArray.Add("Load");
		ItemArray.Add("Continuous");
		ItemArray.Add("AuxiliaryWorkCenters");
		ItemArray.Add("Count");
		ItemArray.Add("UnitOfMeasure");
		ItemArray.Add("Control");
		ItemArray.Add("Repeatable");
		ItemArray.Add("Skippable");
		ItemArray.Add("OperationKind");
		ItemArray.Add("CLASSIFIEROFTECHNOLOGICALOPERATIONS");
		ItemArray.Add("SetupSettings");
		
		ProductionProcessEditorClientServer.SetPropertyOfFormElements(Items,
			ItemArray, "ReadOnly", Not ItemsAvailability, MatchingElements);
		
		Items[MatchingElements.Description].ChoiceButton = ItemsAvailability;
		
	EndIf;
	
	ProductionProcessEditorClientServer.SetPropertyOfFormElements(Items,
		MatchingElements.SetupSettings, "Enabled", SetupSettingsAreUsed);
	
	VisibilityOfParameters = True;
	
	ProductionProcessEditorClientServer.SetPropertyOfFormElements(Items,
		"GroupQuantity,GroupExecution", "Visible", VisibilityOfParameters, MatchingElements);

	#Region ParametersOfOperationalPlanningAndProductionSites
	
	If DivisionParameters = Undefined Then
		Department = Common.ObjectAttributeValue(Object.Owner, "Department");
		If ValueIsFilled(Department) Then
			DivisionParameters = ProductionServer.ProductionBusinessUnitDescription(Department);
		EndIf;
	EndIf;
	
	If DivisionParameters = Undefined Then
		
		VisibilityOfOperationalPlanningParameters = True;
		VisibilityOfParametersOfProductionSites = True;
		
	Else
		
		VisibilityOfOperationalPlanningParameters = (DivisionParameters.UseManufacturingExecutionSystem
					And Not Object.ContainsTechnologicalProcess
					);
		VisibilityOfParametersOfProductionSites = (DivisionParameters.UseAreas
					Or (Not DivisionParameters.UseAreas
						And ValueIsFilled(Object.ProductionArea))
					);
		
		If GetFunctionalOption("UseOperationExecutionControl") Then
			ProductionProcessEditorClientServer.SetPropertyOfFormElements(Items,
				MatchingElements.Control, "Visible",
				Not DivisionParameters.UseManufacturingExecutionSystem
					Or Object.Control <> Enums.ManufacturingOperationControlOptions.NotRequired);
		EndIf;
		
	EndIf;
	
	ProductionProcessEditorClientServer.SetPropertyOfFormElements(Items,
		"GroupTransferBatch,Continuous,AuxiliaryWorkCentersPage",
		"Visible",
		VisibilityOfOperationalPlanningParameters,
		MatchingElements);
	ProductionProcessEditorClientServer.SetPropertyOfFormElements(Items,
		MatchingElements.ProductionArea,
		"Visible",
		VisibilityOfParametersOfProductionSites);
	
	#EndRegion
	
	ConfigureVisibilityAccessibilityByRCDetails(Form, MatchingElements);
	
EndProcedure

Procedure CheckCorrectSetupOption(Object) Export
	
	If ValueIsFilled(Object.SetupSettings) Then
		
		If ValueIsFilled(Object.WorkCenter) Then
			
			Query = New Query;
			Query.Text = "
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Catalog.WorkCenterTypes AS WorkCenterTypes
			|
			|	LEFT JOIN Catalog.WorkCenters AS WorkCenters
			|	ON WorkCenterTypes.Ref = WorkCenters.WorkCenterType
			|
			|	INNER JOIN Catalog.SetupOptions AS SetupOptions
			|	ON SetupOptions.Ref = &SetupSettings
			|		AND &WorkCenter IN (WorkCenters.Ref, WorkCenterTypes.Ref)
			|		AND WorkCenterTypes.Ref = SetupOptions.Owner
			|";
			Query.SetParameter("SetupSettings", Object.SetupSettings);
			Query.SetParameter("WorkCenter",   Object.WorkCenter);
			
			If Query.Execute().IsEmpty() Then
				
				Object.SetupSettings = Catalogs.SetupOptions.EmptyRef();
				
			EndIf;
			
		Else
			
			Object.SetupSettings = Catalogs.SetupOptions.EmptyRef();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Plot representation.
// 
// Parameters:
//  Object - CatalogRef.ManufacturingOperations
//  VisibilityOfSectionElement - Boolean
// 
// Returns:
//  String - Plot representation
Function PlotPresentation(Object, VisibilityOfSectionElement) Export
	
	Result = "";
	
	If VisibilityOfSectionElement
		And ValueIsFilled(Object.WorkCenter)
		And TypeOf(Object.WorkCenter) = Type("CatalogRef.WorkCenters") Then
		Result = String(Common.ObjectAttributeValue(Object.WorkCenter, "ProductionArea"));
	EndIf;
	
	Return Result;
	
EndFunction

#Region AdditionalDetailsOfTypeOfOperation

// Sets the conditional registration of the details of the type of operation
// 
// Parameters:
// 	The Reference object object.Technological operations
// 	Form - ClientApplicationForm
// 	ElementPrefix - String
// 	MatchingElements - Structure
Procedure SetConditionalAppearanceOfTransactionTypeDetails(Form, ElementPrefix = "", MatchingElements = Undefined) Export
	
	ConditionalAppearance  = Form.ConditionalAppearance; // DataCompositionConditionalAppearance
	Items            = Form.Items;
	
	If MatchingElements = Undefined Then
		MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	EndIf;
	
	ElementMinValue  = Items[MatchingElements.AddAttributesValueMin];  // FormField
	ValueElementMax = Items[MatchingElements.AddAttributesValueMax]; // FormField
	ElementAdditionalDetails = Items[MatchingElements.AddAttributes];             // FormTable
	
	AddAttributes        = Form[MatchingElements.AddAttributes];
	
	//
	
	SettingPresentation = NStr("vi = 'Các mục tin của dạng giao dịch';
								|ru = 'Реквизиты вида операции';
								|en = 'Operation type attributes'; fa = 'Operation type attributes';
								|it = 'Requisiti del tipo di operazione';
								|pl = 'Atrybuty rodzaju operacji';
								|tr = 'İşlem türünün öznitelikleri'");
	
	DeleteDesignElements = New Array;
	For Each Item In ConditionalAppearance.Items Do
		If Item.Presentation = SettingPresentation Then
			DeleteDesignElements.Add(Item);
		EndIf;
	EndDo;
	For Each Item In DeleteDesignElements Do
		ConditionalAppearance.Items.Delete(Item);
	EndDo;
	
	PropertiesWithoutStandards = New ValueList;
	
	//
	
	For Each String In AddAttributes Do
		
		If String.ValueType.Types().UBound() = 0
			And String.ValueType.ContainsType(Type("Number")) Then
			
			Item = ConditionalAppearance.Items.Add();
			Item.Presentation = SettingPresentation;
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(ElementMinValue.Name);
			
			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(ValueElementMax.Name);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(MatchingElements.AddAttributes+".Property");
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = String.Property;
			
			Item.Appearance.SetParameterValue("Format", String.Format);
			
		Else
			
			PropertiesWithoutStandards.Add(String.Property);
			
		EndIf;
		
	EndDo;
	
	//
	
	If PropertiesWithoutStandards.Count() > 0 Then
		
		Item = ConditionalAppearance.Items.Add();
		Item.Presentation = SettingPresentation;
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ElementMinValue.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(MatchingElements.AddAttributes+".Property");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = PropertiesWithoutStandards;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
		Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa sử dụng>';
														|ru = '<не используются>';
														|en = '<not used>'; fa = '<استفاده نمی‌شود>';
														|it = '<non vengono utilizzati>';
														|pl = '<nie jest używane>';
														|tr = '<kullanılmamaktadır>'"));
		Item.Appearance.SetParameterValue("ReadOnly", True);
		
		//
		
		Item = ConditionalAppearance.Items.Add();
		Item.Presentation = SettingPresentation;
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(ValueElementMax.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(MatchingElements.AddAttributes+".Property");
		ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
		ItemFilter.RightValue = PropertiesWithoutStandards;
		
		Item.Appearance.SetParameterValue("Visible", False);
		
	EndIf;
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	Item.Presentation = SettingPresentation;
			
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ElementAdditionalDetails.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(MatchingElements.AddAttributes+".Removed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", New Font(,,,,,True));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
EndProcedure

// Reads the details of the operation type
// 
// Parameters:
// 	Object - CatalogObject.ManufacturingOperations
// 	Form - ClientApplicationForm
// 	ElementPrefix - String
// 	MatchingElements - Structure
Procedure ReadTransactionTypeDetails(Object, Form, ElementPrefix = "", MatchingElements = Undefined) Export
	
	If MatchingElements = Undefined Then
		MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	EndIf;
	
	If Object.OperationKind.IsEmpty() Then
		Form[MatchingElements.AddAttributes].Clear();
		Form[MatchingElements.AdditionalAttributesQuantity] = 0;
		Return;
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	
	Catalogs.TechnologicalOperationKinds.CreateTTSetProperties(
		Object.OperationKind,
		TempTablesManager,
		True,
		False);
	
	Query = New Query(
		"SELECT
		|	Standards.Property     AS Property,
		|	Standards.ValueMin  AS ValueMin,
		|	Standards.ValueMax AS ValueMax
		|INTO TTStandards
		|FROM
		|	&Standards AS Standards
		|
		|INDEX BY
		|	Property
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetProperties.Property             AS Property,
		|	SetProperties.Title            AS Title,
		|	SetProperties.ValueType          AS ValueType,
		|	SetProperties.FormatProperties       AS Format,
		|	SetProperties.LineNumber          AS LineNumber,
		|	3                                   AS PictureNumber,
		|	ISNULL(Standards.ValueMin, 0)  AS ValueMin,
		|	ISNULL(Standards.ValueMax, 0) AS ValueMax,
		|	FALSE                                AS Removed
		|FROM
		|	TTSetProperties AS SetProperties
		|		LEFT JOIN TTStandards AS Standards
		|		ON SetProperties.Property = Standards.Property
		|WHERE
		|	NOT SetProperties.IsAdditionalInfo
		|	AND NOT SetProperties.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	Standards.Property,
		|	Standards.Property.Title,
		|	Standards.Property.ValueType,
		|	Standards.Property.FormatProperties,
		|	0,
		|	3,
		|	Standards.ValueMin,
		|	Standards.ValueMax,
		|	TRUE
		|FROM
		|	TTStandards AS Standards
		|		LEFT JOIN TTSetProperties AS SetProperties
		|		ON Standards.Property = SetProperties.Property
		|			AND (NOT SetProperties.DeletionMark)
		|WHERE
		|	SetProperties.Property IS NULL
		|
		|ORDER BY
		|	Removed,
		|	LineNumber
		|");
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Standards", Object.OperationKindStandards.Unload());
	
	AddAttributes = Query.Execute().Unload();
	
	Form[MatchingElements.AddAttributes].Load(AddAttributes);
	Form[MatchingElements.AdditionalAttributesQuantity] = AddAttributes.Count();
	
	// Filling in the format of additional details
	For Each String In Form[MatchingElements.AddAttributes] Do
		
		If String.ValueType.ContainsType(Type("Number")) Then
			
			If ValueIsFilled(String.Format) Then
				
				If StrFind(String.Format, "ND") = 0 Then
					String.Format = String.Format + "; ND=" + String.ValueType.NumberQualifiers.Digits;
				EndIf;
				
				If StrFind(String.Format, "NFD") = 0 Then
					String.Format = String.Format + "; NFD=" + String.ValueType.NumberQualifiers.FractionDigits;
				EndIf;
				
			Else
				
				String.Format = StrTemplate("ND=%1; NFD=%2",
					String.ValueType.NumberQualifiers.Digits,
					String.ValueType.NumberQualifiers.FractionDigits);
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	SetConditionalAppearanceOfTransactionTypeDetails(Form,,MatchingElements);
	
EndProcedure

Procedure OperationKindOnChange(Object, Form, ElementPrefix = "") Export
	
	MatchingElements = ProductionProcessEditorClientServer.MatchingElements(ElementPrefix);
	
	AddAttributes  = Form[MatchingElements.AddAttributes];
	OperationKind   = Form[MatchingElements.OperationKind];
	
	If Object.OperationKind <> OperationKind Then
		
		AddAttributes.Clear();
		Form[MatchingElements.AdditionalAttributesQuantity] = AddAttributes.Count();
		Form[MatchingElements.OperationKind]            = Object.OperationKind;
		
		Object.OperationKindStandards.Clear();
		
	ElsIf Not Object.OperationKind.IsEmpty() Then
		
		ProductionProcessEditorClientServer.UploadOperationTypeStandards(Object, AddAttributes);
		
	EndIf;
	
	ReadTransactionTypeDetails(Object, Form,, MatchingElements);
	
EndProcedure

#EndRegion

#EndRegion

#Region WorksToPerform

// Configures the operation elements
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	AttributeAvailability - Boolean
Procedure AdjustVisibilityAvailabilityOfWorkItems(Form, AttributeAvailability) Export
	
	If Not Form.ReadOnly Then
		
		ItemArray = New Array;
		ItemArray.Add("WorksPerformedItems");
		ItemArray.Add("WorksPerformedCharacteristics");
		ItemArray.Add("WorkPerformedQuantity");
		ItemArray.Add("WorkPerformedIsCarriedOutInProcess");
		ItemArray.Add("WorksBeingPerformedBillOfMaterials");
		ItemArray.Add("WorksPerformedFinishedProductToBeRepairedItem");
		ItemArray.Add("WorksPerformedFinishedProductBeingRepairedCharacteristics");
		ItemArray.Add("WorksPerformedProductCostingElements");
		
		ProductionProcessEditorClientServer.SetPropertyOfFormElements(Form.Items,
			ItemArray, "ReadOnly", Not AttributeAvailability);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillChecking

// Table constructor for checking the sequence of production process elements
// 
// Returns:
// 	ValueTable - LongDesc:
// * Ref - CatalogRef.ProductionStages,CatalogRef.ManufacturingOperations
// * Description - String
// * Number - Number
// * TheNumberOfTheNextOne - Number
Function TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner() Export
	
	Result = New ValueTable;
	
	ArrayOfLinkTypes = New Array;
	ArrayOfLinkTypes.Add(Type("CatalogRef.ProductionStages"));
	ArrayOfLinkTypes.Add(Type("CatalogRef.ManufacturingOperations"));
	ObjectTypesArray = New Array;
	ObjectTypesArray.Add(Type("CatalogObject.ProductionStages"));
	ObjectTypesArray.Add(Type("CatalogObject.ManufacturingOperations"));
	ObjectTypesArray.Add(Type("FormDataTreeItem"));
	ObjectTypesArray.Add(Type("FormDataCollectionItem"));
	ObjectTypesArray.Add(Type("ValueTableRow"));
	Result.Columns.Add("Object",                     New TypeDescription(ObjectTypesArray));
	Result.Columns.Add("Presentation",              New TypeDescription("String",,,,New StringQualifiers(100)));
	
	Result.Columns.Add("Operation",                   New TypeDescription(ArrayOfLinkTypes));
	Result.Columns.Add("OperationNumber",              New TypeDescription("Number"));
	Result.Columns.Add("NextOperation",     New TypeDescription("Number"));
	Result.Columns.Add("ThereIsNoNextOperation",       New TypeDescription("Boolean"));
	Result.Columns.Add("NextOperationNumberField", New TypeDescription("String"));
	Result.Columns.Add("ControlSequenceError", New TypeDescription("Boolean"));
	Result.Columns.Add("ControlUnitError",   New TypeDescription("Boolean"));
	Result.Columns.Add("ControlIndividualOfOperationsInSequence", New TypeDescription("Boolean"));
	
	Result.Columns.Add("WorkPlanningStageIsLast", New TypeDescription("Boolean"));
	Return Result;
	
EndFunction

// Checks the order of the elements of the production process
// 
// Parameters:
//	TableOfElements - See TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner
//	StructureOfChecks - Structure
// 	Cancel - Boolean
// 	Messages - Array - array for collecting messages
// 	ObjectOwner - CatalogObject.ProductionStages
//
Procedure CheckOrderOfProductionProcessElements(TableOfElements, StructureOfChecks, Cancel, Messages = Undefined, ObjectOwner = Undefined) Export
	
	If TableOfElements.Count() = 0 Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("OperationNumber");
	
	TableOfElements.FillValues("Number next_", "NextOperationNumberField");
	TableOfElements.Indexes.Add("OperationNumber");
	
	For IndexOf = 0 To TableOfElements.Count() - 1 Do
		
		CurrentRow = TableOfElements[IndexOf];
		
		TheStructureOfTheSearch.OperationNumber = CurrentRow.NextOperation;
		FollowingOperations = TableOfElements.FindRows(TheStructureOfTheSearch);
		
		If Not ValueIsFilled(FollowingOperations) And CurrentRow.NextOperation <> 0 Then
			CurrentRow.ThereIsNoNextOperation = True;
		EndIf;
		ControlOperations = Undefined;
		If StructureOfChecks.Property("ControlOperations", ControlOperations)
			And CurrentRow.Object.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations Then
			
			If Not ValueIsFilled(FollowingOperations) Then
				CurrentRow.ControlSequenceError = True;
			Else
				For Each NextOperation In FollowingOperations Do
					
					If NextOperation.Object.Control <> Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations
						And NextOperation.Object.Control <> Enums.ManufacturingOperationControlOptions.Required2 Then
						CurrentRow.ControlSequenceError = True;
					EndIf;
					
					If (NextOperation.Object.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations
							Or NextOperation.Object.Control = Enums.ManufacturingOperationControlOptions.Required2)
						And CurrentRow.Object.UnitOfMeasure <> NextOperation.Object.UnitOfMeasure Then
						CurrentRow.ControlUnitError = True;
					EndIf;
					
					If ControlOperations.Property("ControlIndividualOfOperationsInSequence") Then
						
						If Not ValueIsFilled(CurrentRow.Operation) Then
							CurrentRow.ControlIndividualOfOperationsInSequence = True;
						EndIf;
						
						If Not ValueIsFilled(NextOperation.Operation)
							And (NextOperation.Object.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations
								Or NextOperation.Object.Control = Enums.ManufacturingOperationControlOptions.Required2) Then
							NextOperation.ControlIndividualOfOperationsInSequence = True;
						EndIf;
						
					EndIf;
					
				EndDo;
			EndIf;
			
		EndIf;
		
		If StructureOfChecks.Property("WorkPlanningStageIsLast")
			And CurrentRow.Object.WorkPlanning
			And CurrentRow.NextOperation = 0 Then
			CurrentRow.WorkPlanningStageIsLast = True;
		EndIf;
		
	EndDo;
	
	If Not SequenceOfListOfOperationsIsCorrect(TableOfElements, StructureOfChecks) Then
		Cancel = True;
	EndIf;
	
	DataKey = Undefined;
	If ObjectOwner <> Undefined Then
		DataKey = ?(ObjectOwner.IsNew(), ObjectOwner.GetNewObjectRef(), ObjectOwner.Ref);
	EndIf;
	
	ProcessMessagesToUser(Messages, DataKey);
	
EndProcedure

// Checks the sequence of specification steps or route map operations
//
// Parameters:
//  OwnerOfOperations	 - CatalogRef	 - link to the owner of operations
//  ParametersStructure	 - Structure		 - required fields: 
//  											The name of the right operation, field operation, field operation of the next operation
//  StructureOfChecks	 - Structure		 - list of checks and error message texts
//  Cancel				 - Boolean			 - indicates whether the current action is canceled.
// 
// Returns:
//  Boolean - true if the sequence of operations is correct.
//
Function SequenceOfOperationsIsCorrect(OwnerOfOperations, ParametersStructure, StructureOfChecks, Cancel = False) Export
	
	QueryText = "
	|	SELECT
	|	CatOperations.Ref AS Operation,
	|	CatOperations.Presentation AS Presentation,
	|	
	|	&CorrectnessOfSequenceOfControlOperations,
	|	&WorkPlanningStageIsLast,
	|	
	|	CatOperations.OperationNumber AS OperationNumber,
	|	CatOperations.NextOperation AS NextOperation,
	|	MAX(CASE
	|		WHEN CatFollowingOperations.Ref IS NULL 
	|				AND CatOperations.NextOperation <> 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS ThereIsNoNextOperation
	|
	|FROM
	|	&ManufacturingOperations AS CatOperations
	|		LEFT JOIN &ManufacturingOperations AS CatFollowingOperations
	|		ON CatOperations.NextOperation = CatFollowingOperations.OperationNumber
	|			AND (CatFollowingOperations.Owner = &Owner)
	|			AND (NOT CatFollowingOperations.DeletionMark)
	|WHERE
	|	CatOperations.Owner = &Owner
	|	AND NOT CatOperations.DeletionMark
	|
	|GROUP BY
	|	CatOperations.Ref,
	|	CatOperations.Presentation,
	|	CatOperations.OperationNumber,
	|	CatOperations.NextOperation
	|";
	
	TextControlOperations = "";
	If StructureOfChecks.Property("ControlOperations") Then
		TextControlOperations = TextCorrectnessOfSequenceOfControlOperations();
	EndIf;
	QueryText = StrReplace(QueryText, "&CorrectnessOfSequenceOfControlOperations," , TextControlOperations);
	
	TextWorkPlanning = "";
	If StructureOfChecks.Property("WorkPlanningStageIsLast") Then
		TextWorkPlanning = TextWorkPlanningStageIsLastOne();
	EndIf;
	QueryText = StrReplace(QueryText, "&WorkPlanningStageIsLast," , TextWorkPlanning);
	
	QueryText = StrReplace(QueryText, ".OperationNumber", "."+ParametersStructure.OperationNumberField);
	QueryText = StrReplace(QueryText, ".NextOperation", "."+ParametersStructure.NextOperationNumberField);
	QueryText = StrReplace(QueryText, "&ManufacturingOperations", "Catalog."+ParametersStructure.NameOfOperationsCatalog);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Owner", OwnerOfOperations);
	
	TransactionList = Query.Execute().Unload();
	
	TransactionList.Columns.Add("NextOperationNumberField", New TypeDescription("String",, New StringQualifiers));
	TransactionList.FillValues(ParametersStructure.NextOperationNumberField, "NextOperationNumberField");
	
	HasErrors = Not SequenceOfListOfOperationsIsCorrect(TransactionList, StructureOfChecks, OwnerOfOperations);
	
	Cancel = Cancel Or HasErrors;
	
	Return Not HasErrors;
	
EndFunction

// Checks the specified list of operations/stages for correctness using the following criteria:
// - there is a first operation and it is one;
// - there is a last operation;
// - all subsequent operations are available.
//
// Parameters:
//	TransactionList - ValueTable - operations/stages to check, columns:
//		* Operation - CatalogRef - link to the stage / operation.
//		* Presentation - String - representation of a stage / operation.
//		* OperationNumber - Number - operation number.
//		* NextOperation - Number - number of the next operation.
//		* ThereIsNoNextOperation - Boolean - flag that the list does not contain an operation
//			whose number is specified as the number of the next operation.
//		* NextOperationNumberField - String - name of the form details to
//			link the message about the absence of the next operation to.
//  StructureOfChecks - Structure - list of checks and error message texts
//  OwnerOfOperations - CatalogRef - link to the owner of operations.
//
// Returns:
//   Boolean   - true if the sequence of operations is correct.
//
Function SequenceOfListOfOperationsIsCorrect(TransactionList, StructureOfChecks, OwnerOfOperations = Undefined) Export
	
	HasErrors = False;
	
	#Region NoFirstOperation_MultipleFirstOperations
	
	StringsList = TransactionList.FindRows(New Structure("OperationNumber", 1));
	If StructureOfChecks.Property("NoFirstOperation")
		And StringsList.Count() = 0 Then
		
		CommonClientServer.MessageToUser(
			StructureOfChecks.NoFirstOperation,
			OwnerOfOperations,
			,
			,
			HasErrors);
		
	ElsIf StructureOfChecks.Property("FirstFewOperations")
		And StringsList.Count() > 1 Then
		
		CommonClientServer.MessageToUser(
			StructureOfChecks.FirstFewOperations,
			OwnerOfOperations,
			,
			,
			HasErrors);
		
	EndIf;
	
	#EndRegion
	
	#Region NoLastOperation_MultipleLastOperations
	
	StringsList = TransactionList.FindRows(New Structure("NextOperation", 0));
	If StructureOfChecks.Property("NoLastOperation")
		And StringsList.Count() = 0 Then
		
		CommonClientServer.MessageToUser(
			StructureOfChecks.NoLastOperation,
			OwnerOfOperations,
			,
			,
			HasErrors);
		
	ElsIf StructureOfChecks.Property("FewRecentOperations")
		And StringsList.Count() > 1 Then
		
		CommonClientServer.MessageToUser(
			StructureOfChecks.FewRecentOperations,
			OwnerOfOperations,
			,
			,
			HasErrors); 
		
	EndIf;
	
	#EndRegion
	
	#Region ThereIsNoNextOperation
	
	If StructureOfChecks.Property("ThereIsNoNextOperation") Then
		
		StringsList = TransactionList.FindRows(New Structure("ThereIsNoNextOperation", True));
		For Each CollectionItem In StringsList Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				StructureOfChecks.ThereIsNoNextOperation,
				CollectionItem.Presentation);
				
			CommonClientServer.MessageToUser(
				MessageText,
				CollectionItem.Operation,
				CollectionItem.NextOperationNumberField,
				,
				HasErrors);
			
		EndDo;
		
	EndIf;

	#EndRegion
	
	#Region ControlOperations
	
	If StructureOfChecks.Property("ControlOperations") Then
		
		StringsList = TransactionList.FindRows(New Structure("ControlSequenceError", True));
		For Each CollectionItem In StringsList Do
			
			MessageText = StrTemplate(StructureOfChecks.ControlOperations.ControlSequenceError,
				CollectionItem.Presentation);
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				,
				,
				HasErrors);
			
		EndDo;
		
		StringsList = TransactionList.FindRows(New Structure("ControlUnitError", True));
		For Each CollectionItem In StringsList Do
			
			MessageText = StrTemplate(StructureOfChecks.ControlOperations.ControlUnitError,
				CollectionItem.Presentation);
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				,
				,
				HasErrors);
			
		EndDo;
		
		StringsList = TransactionList.FindRows(New Structure("ControlIndividualOfOperationsInSequence", True));
		For Each CollectionItem In StringsList Do
			
			MessageText = StrTemplate(StructureOfChecks.ControlOperations.ControlIndividualOfOperationsInSequence,
				CollectionItem.Presentation);
			
			CommonClientServer.MessageToUser(
				MessageText,
				,
				,
				,
				HasErrors);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region WorkPlanning
	
	If StructureOfChecks.Property("WorkPlanningStageIsLast") Then
		
		StringsList = TransactionList.FindRows(New Structure("WorkPlanningStageIsLast", True));
		For Each CollectionItem In StringsList Do
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				StructureOfChecks.WorkPlanningStageIsLast,
				CollectionItem.Presentation);
				
			CommonClientServer.MessageToUser(
				MessageText,
				CollectionItem.Operation,
				CollectionItem.NextOperationNumberField,
				,
				HasErrors);
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	Return Not HasErrors;
	
EndFunction

// Checks the filling in of the production stage details
// 
// Parameters:
// 	StageObject - CatalogObject.ProductionStages
// 	Cancel - Boolean
// 	Messages - Array - array for collecting messages
Procedure CheckStageDetails(StageObject, Cancel = False, Messages = Undefined) Export
	
	DataKey = ?(StageObject.IsNew(), StageObject.GetNewObjectRef(), StageObject.Ref);
	
	If Not StageObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	ProcessMessagesToUser(Messages, DataKey, True);
	
EndProcedure

Procedure CheckProductionStepsOnSide(Stages, SpecificationData, Cancel = False, Messages = Undefined) Export
	
	If Stages.Count() = 0 Then
		Return;
	EndIf;
	
	// Production on the side is only available for the "Manufacture, Assembly" type of production process
	If SpecificationData.ProductionProcessType <> Enums.ProductionProcessTypes.Assembly Then
		MessageText = StrTemplate(NStr("vi = 'Trong bảng kê chi tiết các nguồn lực sản xuất ""%1"" không cho phép sử dụng các bước được thực hiện bởi bên nhận gia công';
										|ru = 'В спецификации типа ""%1"" не допускается использовать этапы, выполняемые переработчиком';
										|en = 'Cannot use the stages performed by the subcontractor in BOM of the %1 type'; fa = 'Cannot use the stages performed by the subcontractor in BOM of the %1 type';
										|it = 'Le specifiche del tipo ""%1"" non sono autorizzate a utilizzare le fasi eseguite dal subfornitore';
										|pl = 'W specyfikacji typu ""%1"" nie można używać etapów, wykonywanych przez przetwórcę';
										|tr = '""%1"" türündeki ürün reçetesinde, fason üretici tarafından gerçekleştirilen aşamaların kullanılmasına izin verilmemektedir'"),
			SpecificationData.ProductionProcessType);
		Common.MessageToUser(MessageText,,,, Cancel);
		Return;
	EndIf;
	
	// In the SPACECRAFT, it is not allowed to use the stages performed by the processor in a multi-stage specification
	If SpecificationData.MultiStageProductionProcess And GetFunctionalOption("ComplexAutomation") Then
		MessageText = NStr("vi = 'Trong bảng kê chi tiết các nguồn lực sản xuất nhiều công đoạn, không được phép sử dụng các bước được thực hiện bởi bên nhận gia công';
							|ru = 'В многоэтапной спецификации не допускается использовать этапы, выполняемые переработчиком';
							|en = 'Cannot use stages executed by the subcontractor in multi-stage BOM'; fa = 'Cannot use stages executed by the subcontractor in multi-stage BOM';
							|it = 'In una specifica multifase, non è consentito utilizzare le fasi eseguite dal subfornitore';
							|pl = 'W specyfikacji wieloetapowej nie można używać etapów, wykonywanych przez przetwórcę';
							|tr = 'Çok aşamalı ürün reçetesinde, fason üretici tarafından gerçekleştirilen aşamaların kullanılmasına izin verilmemektedir'");
		Common.MessageToUser(MessageText,,,, Cancel);
		Return;
	EndIf;
	
	StageData_1 = New ValueTable;
	StageData_1.Columns.Add("Ref", New TypeDescription("CatalogRef.ProductionStages"));
	StageData_1.Columns.Add("Description", New TypeDescription("String"));
	StageData_1.Columns.Add("ProductionByThirdParty", New TypeDescription("Boolean"));
	StageData_1.Columns.Add("StageNumber", New TypeDescription("Number"));
	StageData_1.Columns.Add("NextStageNo", New TypeDescription("Number"));
	
	For Each Stage In Stages Do
		FillPropertyValues(StageData_1.Add(), Stage);
	EndDo;
	
	TableMaterialsAndServices = SpecificationData.MaterialsAndServices.Unload();
	OutputProductTable  = SpecificationData.ManufacturedProducts.Unload();
	TableReturnableWaste = SpecificationData.RecyclableWaste.Unload();
	TableIntermediateRelease = SpecificationData.IntermediateRelease.Unload();
	QueryText = "
	|SELECT
	|	StageData_1.Ref,
	|	StageData_1.Description,
	|	StageData_1.ProductionByThirdParty,
	|	StageData_1.StageNumber,
	|	StageData_1.NextStageNo
	|INTO TTStageData
	|FROM
	|	&StageData_1 AS StageData_1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndServices.LineNumber                                                   AS LineNumber,
	|	CAST(MaterialsAndServices.Products AS Catalog.Products)            AS Products,
	|	CAST(MaterialsAndServices.StageEditing AS Catalog.ProductionStages) AS StageEditing,
	|	MaterialsAndServices.ProducedInProcess                                         AS ProducedInProcess,
	|	CASE
	|		WHEN MaterialsAndServices.SourceOfSemiFinishedProduct REFS Catalog.ProductionStages
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                          AS ProducedOnStage,
	|	CASE
	|		WHEN MaterialsAndServices.SourceOfSemiFinishedProduct REFS Catalog.ProductionStages
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                                          AS ManufacturedByBOM
	|INTO TTTable
	|FROM
	|	&MaterialsAndServices AS MaterialsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StageList.Ref                AS Ref,
	|	StageList.ProductionByThirdParty AS ProductionByThirdParty
	|INTO TTListOfStages
	|FROM
	|	TTStageData AS StageList
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.ProductionStages.EmptyRef),
	|	MAX(StageList.ProductionByThirdParty)
	|FROM
	|	TTStageData AS StageList
	|WHERE
	|	StageList.StageNumber = 1
	|
	|INDEX BY
	|	StageList.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndServices.LineNumber                       AS LineNumber,
	|	MaterialsAndServices.Products                      AS Products,
	|	ISNULL(StageList.ProductionByThirdParty, FALSE) AS ProductionByThirdParty,
	|	MaterialsAndServices.ProducedInProcess             AS ProducedInProcess,
	|	MaterialsAndServices.ProducedOnStage               AS ProducedOnStage,
	|	MaterialsAndServices.ManufacturedByBOM        AS ManufacturedByBOM
	|INTO TTMaterialsAndServices
	|FROM
	|	TTTable AS MaterialsAndServices
	|		LEFT JOIN TTListOfStages AS StageList
	|		ON MaterialsAndServices.StageEditing = StageList.Ref
	|;
	|
	|SELECT
	|	Table.Ref               AS Stage,
	|	Table.Description         AS StageName,
	|	Table.StageNumber           AS StageNumber,
	|	Table.NextStageNo AS NextStageNo
	|FROM
	|	TTStageData AS Table
	|WHERE 
	|	 Table.ProductionByThirdParty
	|
	|ORDER BY
	|	StageNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS LineNumber
	|WHERE
	|	FALSE
	|";
	
	SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("MaterialsAndServices", TableMaterialsAndServices);
	Query.SetParameter("StageData_1", StageData_1);
	
	Result = Query.ExecuteBatch();
	NumberOfPackages_ = Result.Count();
	
	// For the stages performed on the side, the materials and output products must be described
	If Not Result[NumberOfPackages_ - 3].IsEmpty() Then
		
		If SpecificationData.MultiStageProductionProcess Then
			FilterParameters = New Structure;
			FilterParameters.Insert("StageEditing");
			
			SenderSelectionParameters = New Structure;
			SenderSelectionParameters.Insert("StageSender");
			
			SelectionParametersRecipient = New Structure;
			SelectionParametersRecipient.Insert("RecipientStage");
			
			SelectionParametersForEmptyStage = New Structure;
			SelectionParametersForEmptyStage.Insert("StageEditing", Catalogs.ProductionStages.EmptyRef());
			
			TextTemplateNoLinesInTablePart = NStr("vi = 'Đối với công đoạn %1 được thực hiện bởi bên nhận gia công, không có một dòng nào được nhập vào danh sách ""%2""';
													|ru = 'Для этапа %1, выполняемого переработчиком, не введено ни одной строки в список ""%2""';
													|en = 'No lines are entered into the ""%2"" list for stage %1 performed by data subcontractor'; fa = 'No lines are entered into the ""%2"" list for stage %1 performed by data subcontractor';
													|it = 'Per la fase %1, svolta dal processore, non è stata immessa nemmeno una riga nell''elenco ""%2""';
													|pl = 'Dla etapu %1 wykonywanego przez przetwórcę nie wprowadzono żadnego wiersza na liście ""%2""';
													|tr = 'Fason üretici tarafından gerçekleştirilen %1 aşaması için ""%2"" listesine herhangi bir satır girilmedi'");
			
			Selection = Result[NumberOfPackages_ - 2].Select();
			
			While Selection.Next() Do
				
				FilterParameters.StageEditing = Selection.Stage;
				
				ArrayOfRowsOutputProducts = OutputProductTable.FindRows(FilterParameters);
				
				If Selection.NextStageNo = 0 Then
					
					CommonClientServer.SupplementArray(ArrayOfRowsOutputProducts,
						OutputProductTable.FindRows(SelectionParametersForEmptyStage));
						
				EndIf;
				
				ArrayOfRowsReturnableWaste = TableReturnableWaste.FindRows(FilterParameters);
				
				If Selection.NextStageNo = 0 Then
					
					CommonClientServer.SupplementArray(ArrayOfRowsReturnableWaste,
						TableReturnableWaste.FindRows(SelectionParametersForEmptyStage));
						
				EndIf;
				
				ThereIsIntermediateRelease = False;
				If SpecificationData.RecordMethodOfMaterialTransferBetweenStagesLots =
						Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts Then
					ThereIsIntermediateRelease = True;
				ElsIf SpecificationData.RecordMethodOfMaterialTransferBetweenStagesLots =
						Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually Then
					SenderSelectionParameters.StageSender = Selection.Stage;
					ArrayOfLinesIntermediateRelease = TableIntermediateRelease.FindRows(SenderSelectionParameters);
					ThereIsIntermediateRelease = ArrayOfLinesIntermediateRelease.UBound() <> -1;
				EndIf;
				
				// we check all stages except the last one, the last one will be checked by the platform
				If Selection.NextStageNo <> 0
					And ArrayOfRowsReturnableWaste.UBound() = -1
					And Not ThereIsIntermediateRelease Then
					
					MessageText = StrTemplate(TextTemplateNoLinesInTablePart,
						Selection.StageName,
						SpecificationData.PresentationOfTableInForm("RecyclableWaste"));
					
					Common.MessageToUser(
						MessageText, SpecificationData, "RecyclableWaste",, Cancel);
					
				EndIf;
				
				ArrayOfRowsMaterialsAndServices = TableMaterialsAndServices.FindRows(FilterParameters);
				
				If Selection.StageNumber = 1 Then
					
					CommonClientServer.SupplementArray(ArrayOfRowsMaterialsAndServices,
						TableMaterialsAndServices.FindRows(SelectionParametersForEmptyStage));
						
				EndIf;
				
				ThereIsIntermediateReleaseConsumption = False;
				If SpecificationData.RecordMethodOfMaterialTransferBetweenStagesLots =
						Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts
					And Selection.StageNumber <> 1 Then
					ThereIsIntermediateReleaseConsumption = True;
				ElsIf SpecificationData.RecordMethodOfMaterialTransferBetweenStagesLots =
						Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually Then
					SelectionParametersRecipient.RecipientStage = Selection.Stage;
					ArrayOfLinesIntermediateRelease = TableIntermediateRelease.FindRows(SelectionParametersRecipient);
					ThereIsIntermediateReleaseConsumption = ArrayOfLinesIntermediateRelease.UBound() <> -1;
				EndIf;
				
				// At least one material must be described for the stage performed by the processor
				If ArrayOfRowsMaterialsAndServices.UBound() = -1
					And Not ThereIsIntermediateReleaseConsumption Then
					
					MessageText = StrTemplate(TextTemplateNoLinesInTablePart,
						Selection.StageName,
						SpecificationData.PresentationOfTableInForm("MaterialsAndServices"));
					
					Common.MessageToUser(
						MessageText, SpecificationData, "MaterialsAndServices",, Cancel);
						
				EndIf;
				
			EndDo;
		Else
			
			// At least one material must be described for the stage performed by the processor
			If TableMaterialsAndServices.Count() = 0 Then
				
				TextTemplate1 = NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""Vật liệu và Dịch vụ""';
									|ru = 'Не введено ни одной строки в список ""Материалы и услуги""';
									|en = 'No line is entered into the ""Materials and services"" list'; fa = 'No line is entered into the ""Materials and services"" list';
									|it = 'Non è stata immessa nemmeno una riga nell''elenco ""Materiali e servizi""';
									|pl = 'Nie wprowadzono żadnego wiersza do listy ""Materiały i usługi""';
									|tr = '""Malzemeler ve Hizmetler"" listesine herhangi bir satır girilmedi'");
				
				Common.MessageToUser(
					TextTemplate1, SpecificationData, "MaterialsAndServices",, Cancel);
					
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// In the "Materials and Works" list, it is not allowed to specify works for the stages performed by the processor
	If Not Result[NumberOfPackages_ - 1].IsEmpty() Then
		
		TextTemplate1 = NStr("vi = 'Chỉ ra các công việc đối với công đoạn do người nhận gia công khi vô hiệu hóa kế toán theo phiên bản 2.4 (xem dòng %1 của danh sách ""Nguyên vật liệu và công việc"").';
							|ru = 'Указание работ для этапов, выполняемых переработчиком, допускается при отключенном учете по версии 2.4 (см. строку %1 списка ""Материалы и работы"").';
							|en = 'Work specification for the subcontractor stages is available if accounting of version 2.4 is disabled (see the %1 line of the ""Materials and works"" list).'; fa = 'Work specification for the subcontractor stages is available if accounting of version 2.4 is disabled (see the %1 line of the ""Materials and works"" list).';
							|it = 'L''indicazione dei lavori per le fasi eseguibili da parte dell''elaboratore è permessa con la contabilità disattivata nella versione 2.4 (vedi riga %1 dell''elenco ""Materiali e lavori"").';
							|pl = 'Określenie prac dla etapów, wykonywanych przez przetwórcę, jest dopuszczalne przy wyłączonej ewidencji według wersji 2.4 (patrz wiersz %1 listy ""Materiały i prace"").';
							|tr = 'Fason üretici tarafından gerçekleştirilen aşamalara yönelik işlerin belirtilmesine, sürüm 2.4 üzerinden hesap devre dışı bırakıldığında izin verilmektedir (bk. ""Malzemeler ve İşler"" listesinin %1 satırı).'");
		
		Selection = Result[NumberOfPackages_ - 1].Select();
			
		While Selection.Next() Do
			
			Field           = CommonClientServer.PathToTabularSection("MaterialsAndServices", Selection.LineNumber, "Products");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, Selection.LineNumber);
			
			Common.MessageToUser(
				MessageText, SpecificationData, Field,, Cancel);
			
		EndDo;
		
	EndIf;
	
	ProcessMessagesToUser(Messages);
	
EndProcedure

Function StructureOfStageSequenceChecks(ProductionProcessType, ChecksList = "") Export
	
	StructureOfChecks = New Structure;
	
	StructureOfChecks.Insert("NoFirstOperation",    NStr("vi = 'Thiếu công đoạn đầu.';
														|ru = 'Отсутствует первый этап.';
														|en = 'The first stage is missing.'; fa = 'The first stage is missing.';
														|it = 'Prima fase mancante.';
														|pl = 'Brak pierwszego etapu.';
														|tr = 'İlk aşama eksik.'"));
	StructureOfChecks.Insert("NoLastOperation", NStr("vi = 'Thiếu công đoạn cuối.';
													|ru = 'Отсутствует последний этап.';
													|en = 'The last stage is missing.'; fa = 'The last stage is missing.';
													|it = 'Ultima fase mancante.';
													|pl = 'Brak ostatniego etapu.';
													|tr = 'Son aşama eksik.'"));
	StructureOfChecks.Insert("ThereIsNoNextOperation", NStr("vi = 'Công đoạn ""%1"" được liên kết đến công đoạn không tồn tại.';
															|ru = 'Этап ""%1"" ссылается на несуществующий этап.';
															|en = 'Stage ""%1"" refers to a non-existing stage.'; fa = 'Stage ""%1"" refers to a non-existing stage.';
															|it = 'La fase ""%1"" rimanda ad una fase non esistente.';
															|pl = 'Etap ""%1"" odwołuje się do nieistniejącego etapu.';
															|tr = '""%1"" aşaması, var olmayan bir işlemi ifade etmektedir.'"));
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		Or ProductionProcessType = Enums.ProductionProcessTypes.Repair
		Then
		StructureOfChecks.Insert("FewRecentOperations", NStr("vi = 'Không thể có nhiều công đoạn cuối.';
															|ru = 'Не может быть несколько последних этапов.';
															|en = 'There cannot be more than one last stage.'; fa = 'There cannot be more than one last stage.';
															|it = 'Non vi possono essere più fasi finali.';
															|pl = 'Nie może być kilku ostatnich etapów.';
															|tr = 'Birden fazla son aşama olamaz.'"));
	EndIf;
	
	If ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		Or ProductionProcessType = Enums.ProductionProcessTypes.Repair
		Or ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
		Then
		StructureOfChecks.Insert("FirstFewOperations", NStr("vi = 'Không thể có nhiều công đoạn đầu.';
															|ru = 'Не может быть несколько первых этапов.';
															|en = 'There cannot be more than one first stage.'; fa = 'There cannot be more than one first stage.';
															|it = 'Non vi possono essere più fasi prime.';
															|pl = 'Nie może być kilku pierwszych etapów.';
															|tr = 'Birden fazla ilk aşama olamaz.'"));
	EndIf;
	If ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		StructureOfChecks.Insert("WorkPlanningStageIsLast", NStr("vi = 'Công đoạn lập kế hoạch công việc ""%1"" không phải là công đoạn cuối cùng.';
																|ru = 'Этап планирования работ ""%1"" не может быть последним.';
																|en = 'The ""%1"" work planning stage cannot be the last one.'; fa = 'The ""%1"" work planning stage cannot be the last one.';
																|it = 'The ""%1"" work planning stage cannot be the last one.';
																|pl = 'The ""%1"" work planning stage cannot be the last one.';
																|tr = 'İş planlama aşaması ""%1"" son aşama olamaz.'"));
	EndIf;
	If Not IsBlankString(ChecksList) Then
		ChecksArray =  StrSplit(ChecksList, ",");
		For Each KeyAndValue In StructureOfChecks Do
			If ChecksArray.Find(KeyAndValue.Key) = Undefined Then
				StructureOfChecks.Delete(KeyAndValue.Key);
			EndIf;
		EndDo;
	EndIf;
	
	Return StructureOfChecks;
	
EndFunction

Procedure CheckCorrectnessOfFillingInOperations(Owner, Department, Cancel) Export
	
	If Owner.IsEmpty() Or Not ValueIsFilled(Department) Then
		Return;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	ManufacturingOperations.Ref                                                                 AS Ref,
		|	ManufacturingOperations.Presentation                                                          AS Presentation,
		|	BusinessStructure.Presentation                                                             AS DepartmentPresentation,
		|	ManufacturingOperations.Control                                                               AS Control,
		|	ISNULL(WorkCenterTypes.Department, &Department) <> &Department
		|		OR ISNULL(OwnersOfWorkCenters.Department, &Department) <> &Department      AS VRCMembershipError,
		|	BusinessStructure.UseManufacturingExecutionSystem
		|		AND ManufacturingOperations.Control IN (
		|			VALUE(Enum.ManufacturingOperationControlOptions.Required2),
		|			VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations)) AS ControlOptionError
		|FROM
		|	Catalog.ManufacturingOperations AS ManufacturingOperations
		|		LEFT JOIN Catalog.WorkCenterTypes AS WorkCenterTypes
		|		ON ManufacturingOperations.WorkCenter = WorkCenterTypes.Ref
		|		LEFT JOIN Catalog.WorkCenters AS WorkCenters
		|		ON ManufacturingOperations.WorkCenter = WorkCenters.Ref
		|		LEFT JOIN Catalog.WorkCenterTypes AS OwnersOfWorkCenters
		|		ON (WorkCenters.WorkCenterType = OwnersOfWorkCenters.Ref)
		|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
		|		ON BusinessStructure.Ref = &Department
		|WHERE
		|	ManufacturingOperations.Owner = &Owner
		|	AND ManufacturingOperations.DeletionMark = FALSE
		|
		|ORDER BY
		|	ManufacturingOperations.OperationNumber");
	
	Query.SetParameter("Owner",      Owner);
	Query.SetParameter("Department", Department);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		TemplateErrorBelongingToVRC = NStr("vi = 'Nguồn lực sản xuất của giao dịch ""%1"" không thuộc về bộ phận ""%2""';
											|ru = 'Рабочий центр операции ""%1"" не принадлежит подразделению ""%2""';
											|en = 'Work center of the ""%1"" operation does not belong to the ""%2"" business unit'; fa = 'Work center of the ""%1"" operation does not belong to the ""%2"" business unit';
											|it = 'Il centro operativo ""%1"" non appartiene al reparto ""%2""';
											|pl = 'Centrum pracy operacji ""%1"" nie należy do działu ""%2""';
											|tr = '""%1"" işleminin iş merkezi, ""%2"" departmanına ait değildir'");
		ControlVariantErrorTemplate  = NStr("vi = 'Không hỗ trợ sử dụng phương án kiểm soát ""%1"" trong bộ phận có lập kế hoạch theo từng giao dịch';
											|ru = 'Использование варианта контроля ""%1"" в подразделениях с пооперационным планированием не поддерживается';
											|en = 'The ""%1"" control option in business units with Manufacturing Execution System is not supported'; fa = 'The ""%1"" control option in business units with Manufacturing Execution System is not supported';
											|it = 'L''utilizzo della variante di controllo ""%1"" non è supportato nei reparti con pianificazione operativa';
											|pl = 'Użycie wariantu kontroli ""%1"" w działach z planowaniem według operacji nie jest obsługiwane';
											|tr = 'Üretim yürütme sistemli departmanlarda ""%1"" kontrol seçeneğinin kullanılması desteklenmemektedir'");
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			If Selection.VRCMembershipError Then
				MessageText = StrTemplate(TemplateErrorBelongingToVRC, Selection.Presentation, Selection.DepartmentPresentation);
				Common.MessageToUser(MessageText, Selection.Ref,,"Object.WorkCenter", Cancel);
			EndIf;
			
			If Selection.ControlOptionError Then
				MessageText = StrTemplate(ControlVariantErrorTemplate, Selection.Control);
				Common.MessageToUser(MessageText, Selection.Ref,,"Object.Control", Cancel);
			EndIf;
			
			OperationObject = Selection.Ref.GetObject();
			If Not OperationObject.CheckFilling() Then
				Cancel = True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckRouteMapsOfStages(Stages, ValidOnDate, ValidToDate, Cancel = False, Messages = Undefined) Export
	
	RouteSheets = New Array;
	For Each Stage In Stages Do
		If ValueIsFilled(Stage.RouteSheet) Then
			RouteSheets.Add(Stage.RouteSheet);
		EndIf;
	EndDo;
	
	If RouteSheets.Count() = 0 Then
		Return;
	EndIf;
	
	AttributesValues = Catalogs.RouteSheets.ValuesOfRouteMapDetails(RouteSheets);
	
	For Each Stage In Stages Do // CatalogObject.ProductionStages
		
		If Not ValueIsFilled(Stage.RouteSheet) Then
			Continue;
		EndIf;
		
		DataKey = ?(Stage.IsNew(), Stage.GetNewObjectRef(), Stage.Ref);
		
		Catalogs.BillsOfMaterials.CheckCorrectnessOfRouteMap(
			ValidOnDate, ValidToDate, AttributesValues[Stage.RouteSheet], DataKey, Stage.Description, Cancel);
		
	EndDo;
	
	ProcessMessagesToUser(Messages);
	
EndProcedure

Procedure CheckComplianceOfSelectionByProperties(Stages, ObjectSpecification, Cancel = False, Messages = Undefined) Export
	
	MessageTemplate   = NStr("vi = 'Thuộc tính không chính xác được chỉ định trong cài đặt sử dụng, xem dạng trung tâm công việc ""%1"".';
							|ru = 'В настройках использования указаны неверные свойства, см. вид рабочего центра ""%1"".';
							|en = 'Invalid properties are specified in usage settings, see work center type ""%1"".'; fa = 'Invalid properties are specified in usage settings, see work center type ""%1"".';
							|it = 'Proprietà non valide sono specificate nelle impostazioni di utilizzo, vedere il tipo del centro di lavoro ""%1"".';
							|pl = 'W ustawieniach użycia są wskazane nieprawidłowe właściwości, patrz rodzaj centrum w3ykonania pracy ""%1"".';
							|tr = 'Kullanım ayarlarında yanlış özellikler belirtildi, bk. ""%1"" iş merkezi türü.'");
	EmptyLinkKey   = New UUID("00000000-0000-0000-0000-000000000000");
	TheStructureOfTheSearch   = New Structure("ConnectionKey");
	MainProduct   = ProductDataManagementClientServer.MainProductSpecificationData(ObjectSpecification);
	AvailableProperties = ProductDataManagement.GetPropertiesToSelectByProperties(
		MainProduct.ProductKind,,False).UnloadColumn("Property");
	
	For Each Stage In Stages Do // CatalogObject.ProductionStages
		
		If Stage.SelectionByProperties.Count() = 0 Then
			Continue;
		EndIf;
		
		Ref = ?(Stage.IsNew(), Stage.GetNewObjectRef(), Stage.Ref);
		
		For Each TSName In StrSplit("WorkCenterTypes,AlternateWorkCenterTypes",",") Do
			For Each VRCString In Stage[TSName] Do
				If VRCString.ConnectionKey = EmptyLinkKey Then
					Continue;
				EndIf;
				TheStructureOfTheSearch.ConnectionKey = VRCString.ConnectionKey;
				FilterRows = Stage.SelectionByProperties.FindRows(TheStructureOfTheSearch);
				For Each FIlterRow In FilterRows Do
					If AvailableProperties.Find(FIlterRow.Property) = Undefined Then
						CommonClientServer.MessageToUser(
							StrTemplate(MessageTemplate, VRCString.WorkCenterType),
							Ref,
							"WorkCenterTypes",,
							Cancel);
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		
	EndDo;
	
	ProcessMessagesToUser(Messages);
	
EndProcedure

Procedure CheckQuantityCalculationAlgorithm(Stages, ObjectSpecification, Cancel = False, Messages = Undefined) Export
	
	LinesToCheck = New ValueTable;
	LinesToCheck.Columns.Add("Ref");
	LinesToCheck.Columns.Add("TSName");
	LinesToCheck.Columns.Add("LineNumber");
	LinesToCheck.Columns.Add("QuantityCalculationAlgorithm");
	LinesToCheck.Columns.Add("WorkCenterTypePresentation");
	
	For Each Stage In Stages Do // CatalogObject.ProductionStages
		
		Ref = ?(Stage.IsNew(), Stage.GetNewObjectRef(), Stage.Ref);
		
		For Each TSName In StrSplit("WorkCenterTypes,AlternateWorkCenterTypes",",") Do
			For Each VRCString In Stage[TSName] Do
				If Not IsBlankString(VRCString.QuantityCalculationAlgorithm) Then
					NewRow = LinesToCheck.Add();
					FillPropertyValues(NewRow, VRCString);
					NewRow.Ref = Ref;
					NewRow.TSName  = TSName;
					NewRow.WorkCenterTypePresentation = VRCString.WorkCenterType;
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;
	
	If LinesToCheck <> Undefined And LinesToCheck.Count() Then
		
		DescriptionOfSources = Catalogs.BillsOfMaterials.UploadDataForFormulaConstructor(ObjectSpecification, "");
		
		Catalogs.ProductionStages.CheckAlgorithmForCalculatingOperatingTimeOfVRC(LinesToCheck, DescriptionOfSources, False, Cancel);
		
		ProcessMessagesToUser(Messages);
		
	EndIf;
	
EndProcedure

// Checks the filling in of the transaction details
// 
// Parameters:
// 	OperationObject - CatalogObject.ManufacturingOperations
// 	StageObject - CatalogObject.ProductionStages
// 	DivisionParameters - See ProductionServer.ProductionBusinessUnitDescription
// 	Cancel - Boolean
// 	Messages - Array of String - array for collecting messages
Procedure CheckOperationDetails(OperationObject, StageObject, DivisionParameters, Cancel = False, Messages = Undefined) Export
	
	DataKey = ?(OperationObject.IsNew(), OperationObject.GetNewObjectRef(), OperationObject.Ref);
	
	SpecificationStatus_ = Undefined;
	If Not OperationObject.AdditionalProperties.Property("SpecificationStatus_", SpecificationStatus_) Then
		SpecificationStatus_ = Common.ObjectAttributeValue(OperationObject.BillOfMaterials, "Status");
		OperationObject.AdditionalProperties.Insert("SpecificationStatus_", SpecificationStatus_);
	EndIf;
	
	If Not OperationObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	ProcessMessagesToUser(Messages, DataKey, True);
	
	If SpecificationStatus_ = Enums.BOMStatuses.Valid Then
		
		If OperationObject.ContainsTechnologicalProcess Then
			
			TaDetails = Catalogs.TechnologicalProcesses.ValuesOfProcessDetails(OperationObject.TechnologicalProcess);
			
			If StageObject.Department <> TaDetails.Department Then
				
				MessageText = StrTemplate(
					NStr("vi = 'Bộ phận của quy trình kỹ thuật (%1) không tương ứng với bộ phận của công đoạn (""%2"").';
						|ru = 'Подразделение технологического процесса (""%1"") не соответствует подразделению этапа (""%2"").';
						|en = 'The technological process business unit (""%1"") does not match the stage business unit (""%2"").'; fa = 'The technological process business unit (""%1"") does not match the stage business unit (""%2"").';
						|it = 'Il reparto del processo tecnologico (""%1"") non corrisponde al reparto della fase (""%2"").';
						|pl = 'Dział procesu technologicznego (""%1"") nie odpowiada działowi etapu (""%2"").';
						|tr = '(""%1"") teknolojik süreç departmanı, (""%2"") aşamasının departmanına karşılık gelmemektedir.'"),
					TaDetails.Department,
					StageObject.Department);
				
				Common.MessageToUser(MessageText, DataKey,,, Cancel);
				
			EndIf;
			
			If TaDetails.Status <> Enums.TechnologicalProcessStatuses.Valid Then
				
				MessageText = StrTemplate(
					NStr("vi = 'Quy trình kỹ thuật ""%1"" cần có trạng thái ""Có hiệu lực"".';
						|ru = 'Технологический процесс ""%1"" должен иметь статус ""Действует"".';
						|en = 'Technological process ""%1"" must be in ""Valid"" status.'; fa = 'Technological process ""%1"" must be in ""Valid"" status.';
						|it = 'Il processo tecnologico ""%1"" deve avere lo stato ""Attivo"".';
						|pl = 'Proces technologiczny ""%1"" powinien mieć status ""Obowiązuje"".';
						|tr = '""%1"" teknolojik süreci ""Aktif"" durumunda olmalıdır.'"),
					OperationObject.TechnologicalProcess);
				
				Common.MessageToUser(MessageText, DataKey,,, Cancel);
				
			EndIf;
			
		Else
			
		CheckFillingOfOperationWorkCenters(OperationObject, StageObject.Department, DataKey, Cancel);
		
		CheckCorrectnessOfOperationControlOption(OperationObject, DivisionParameters, DataKey, Cancel);
			
			// Checking the details of the type of operation
			For Each String In OperationObject.OperationKindStandards Do
				
				If String.ValueMin > String.ValueMax And String.ValueMax <> 0 Then
					
					MessageText = StrTemplate(NStr("vi = 'Giá trị tối thiểu của mục tin ""%1"" vượt quá giá trị tối đa';
													|ru = 'Минимальное значение реквизита ""%1"" превышает максимальное значение';
													|en = 'The minimum value of the ""%1"" attribute exceeds the maximum value'; fa = 'The minimum value of the ""%1"" attribute exceeds the maximum value';
													|it = 'Il valore minimo del requisito ""%1"" supera quello massimo';
													|pl = 'Minimalna wartość atrybutu ""%1"" przekracza maksymalną wartość';
													|tr = '""%1"" özniteliğinin minimum değeri, maksimum değeri aşmaktadır'"),
						String.Property);
						
					Common.MessageToUser(MessageText, DataKey,,, Cancel);
					
				EndIf;
				
			EndDo;
			
		EndIf;
	
	EndIf;
	
	ProcessMessagesToUser(Messages, DataKey);
	
EndProcedure

Procedure CheckFillingOfOperationWorkCenters(OperationObject, StageSubdivision, DataKey, Cancel = False) Export
	
	WorkCenters = New Array;
	Areas = New Array;
	
	If ValueIsFilled(OperationObject.WorkCenter) Then
		WorkCenters.Add(OperationObject.WorkCenter);
	EndIf;
	
	For Each RCString In OperationObject.AuxiliaryWorkCenters Do
		If ValueIsFilled(RCString.WorkCenter) Then
			WorkCenters.Add(RCString.WorkCenter);
		EndIf;
	EndDo;
	
	If ValueIsFilled(OperationObject.ProductionArea) Then
		Areas.Add(OperationObject.ProductionArea);
	EndIf;
	
	If WorkCenters.Count() Or Areas.Count() > 0 Then
		
		MessageTemplate = NStr("vi = 'Bộ phận %1 ""%2"" (""%3"") không tương ứng với bộ phận trong công đoạn.';
								|ru = 'Подразделение %1 ""%2"" (""%3"") не соответствует подразделению этапа.';
								|en = '%1 ""%2"" (""%3"") business unit does not correspond to the stage business unit.'; fa = '%1 ""%2"" (""%3"") business unit does not correspond to the stage business unit.';
								|it = 'Il reparto %1 ""%2"" (""%3"") non corrisponde al reparto della fase.';
								|pl = 'Dział %1 ""%2"" (""%3"") nie jest zgodny z działem etapu.';
								|tr = '""%2"" %1 (""%3"") departmanına, aşama departmanıyla uyuşmamaktadır.'");
		
		Query = New Query;
		Query.SetParameter("WorkCenters",      WorkCenters);
		Query.SetParameter("StageSubdivision", StageSubdivision);
		Query.SetParameter("Areas", Areas);
		Query.SetParameter("TextRepresentationOfWorkplaceView", NStr("vi = 'dạng nguồn lực sản xuất';
																	|ru = 'вида рабочего центра';
																	|en = 'work center type'; fa = 'work center type';
																	|it = 'tipo di centro di lavoro';
																	|pl = 'rodzaju gniazda produkcyjnego';
																	|tr = 'iş merkezi türünün'")); 
		Query.SetParameter("TextRepresentationOfWorkplace", NStr("vi = 'nguồn lực sản xuất';
																|ru = 'рабочего центра';
																|en = 'work center'; fa = 'work center';
																|it = 'centro di lavoro';
																|pl = 'gniazda produkcyjnego';
																|tr = 'iş merkezinin'")); 
		Query.SetParameter("TextRepresentationOfPlot", NStr("vi = 'khu vực';
															|ru = 'участка';
															|en = 'area'; fa = 'area';
															|it = 'sito';
															|pl = 'area';
															|tr = 'sahanın'")); 
		Query.Text = "SELECT
		|	&TextRepresentationOfWorkplaceView AS ObjectPresentation,
		|	WorkCenterTypes.Presentation AS Presentation,
		|	WorkCenterTypes.Department.Presentation AS DepartmentPresentation
		|FROM
		|	Catalog.WorkCenterTypes AS WorkCenterTypes
		|WHERE
		|	WorkCenterTypes.Ref IN (&WorkCenters)
		|	AND WorkCenterTypes.Department <> &StageSubdivision
		|
		|UNION ALL
		|
		|SELECT
		|	&TextRepresentationOfWorkplace,
		|	WorkCenters.Presentation,
		|	WorkCenters.WorkCenterType.Department.Presentation
		|FROM
		|	Catalog.WorkCenters AS WorkCenters
		|WHERE
		|	WorkCenters.Ref IN (&WorkCenters)
		|	AND WorkCenters.WorkCenterType.Department <> &StageSubdivision
		|
		|UNION ALL
		|
		|SELECT
		|	&TextRepresentationOfPlot,
		|	ProductionSites.Presentation,
		|	ProductionSites.Owner.Presentation AS DepartmentPresentation
		|FROM
		|	Catalog.ProductionSites AS ProductionSites
		|WHERE
		|	ProductionSites.Ref IN (&Areas)
		|	AND ProductionSites.Owner <> &StageSubdivision";
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			
			Selection = Result.Select();
			While Selection.Next() Do
					
				MessageText = StrTemplate(MessageTemplate,
					Selection.ObjectPresentation,
					Selection.Presentation,
					Selection.DepartmentPresentation);
					
				Common.MessageToUser(MessageText, DataKey,,, Cancel);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckCorrectnessOfOperationControlOption(OperationObject, DivisionParameters, DataKey, Cancel = False) Export
	
	If DivisionParameters.UseManufacturingExecutionSystem
		And (OperationObject.Control = Enums.ManufacturingOperationControlOptions.Required2
			Or OperationObject.Control = Enums.ManufacturingOperationControlOptions.RequiredForSubsequentOperations) Then
		
		MessageText = StrTemplate(NStr("vi = 'Không hỗ trợ sử dụng phương án kiểm soát ""%1"" trong bộ phận có lập kế hoạch theo từng giao dịch';
										|ru = 'Использование варианта контроля ""%1"" в подразделениях с пооперационным планированием не поддерживается';
										|en = 'The ""%1"" control option in business units with Manufacturing Execution System is not supported'; fa = 'The ""%1"" control option in business units with Manufacturing Execution System is not supported';
										|it = 'L''utilizzo della variante di controllo ""%1"" non è supportato nei reparti con pianificazione operativa';
										|pl = 'Użycie wariantu kontroli ""%1"" w działach z planowaniem według operacji nie jest obsługiwane';
										|tr = 'Üretim yürütme sistemli departmanlarda ""%1"" kontrol seçeneğinin kullanılması desteklenmemektedir'"),
			OperationObject.Control);
		
		Common.MessageToUser(MessageText, DataKey,,, Cancel);
		
	EndIf;
	
EndProcedure

Function StructureOfOperationSequenceChecks(ChecksList = "", DivisionParameters = Undefined) Export
	
	StructureOfChecks = New Structure;
	
	StructureOfChecks.Insert("FirstFewOperations",    NStr("vi = 'Không thể có nhiều giao dịch đầu.';
															|ru = 'Не может быть несколько первых операций.';
															|en = 'There cannot be several first operations.'; fa = 'There cannot be several first operations.';
															|it = 'Non possono esserci più operazioni prime.';
															|pl = 'Nie może być kilku pierwszych operacji.';
															|tr = 'Birden fazla ilk işlem olamaz.'"));
	StructureOfChecks.Insert("FewRecentOperations", NStr("vi = 'Không thể có nhiều giao dịch cuối.';
														|ru = 'Не может быть несколько последних операций.';
														|en = 'There cannot be several last operations.'; fa = 'There cannot be several last operations.';
														|it = 'Non possono esserci più operazioni ultime.';
														|pl = 'Nie może być kilku ostatnich operacji.';
														|tr = 'Birden fazla son işlem olamaz.'"));
	StructureOfChecks.Insert("NoFirstOperation",          NStr("vi = 'Không có giao dịch đầu.';
																|ru = 'Отсутствует первая операция.';
																|en = 'The first operation is missing.'; fa = 'The first operation is missing.';
																|it = 'Manca l''operazione prima.';
																|pl = 'Brak pierwszej operacji.';
																|tr = 'İlk işlem bulunmamaktadır.'"));
	StructureOfChecks.Insert("NoLastOperation",       NStr("vi = 'Không có giao dịch cuối';
															|ru = 'Отсутствует последняя операция.';
															|en = 'The last operation is missing.'; fa = 'The last operation is missing.';
															|it = 'Manca l''operazione ultima.';
															|pl = 'Brak ostatniej operacji.';
															|tr = 'Son işlem bulunmamaktadır.'"));
	StructureOfChecks.Insert("ThereIsNoNextOperation",       NStr("vi = 'Giao dịch ""%1"" được liên kết đến giao dịch không tồn tại.';
																	|ru = 'Операция ""%1"" ссылается на несуществующую операцию.';
																	|en = 'The ""%1"" operation refers to a non-existing operation.'; fa = 'The ""%1"" operation refers to a non-existing operation.';
																	|it = 'L''operazione ""%1"" rimanda ad un''operazione inesistente.';
																	|pl = 'Operacja ""%1"" odwołuje się do nieistniejącej operacji.';
																	|tr = '""%1"" işlemi, var olmayan bir işlemi ifade etmektedir.'"));
	
	If GetFunctionalOption("UseOperationExecutionControl")
		And (DivisionParameters = Undefined Or Not DivisionParameters.UseManufacturingExecutionSystem) Then
		
		ControlMessages = New Structure;
		
		ControlMessages.Insert("ControlSequenceError",
			NStr("vi = 'Giao dịch ""%1"". Thiếu giao dịch kiểm soát hoàn thành.';
				|ru = 'Операция ""%1"". Отсутствует завершающая контрольная операция.';
				|en = 'The ""%1"" operation. The final control operation is missing.'; fa = 'The ""%1"" operation. The final control operation is missing.';
				|it = 'Operazione ""%1"". Non vi è l''operazione di controllo conclusiva.';
				|pl = 'Operacja ""%1"". Brak końcowej operacji kontrolnej.';
				|tr = '""%1"" işlemi. Son kontrol işlemi bulunmamaktadır.'"));
		ControlMessages.Insert("ControlUnitError",
			NStr("vi = 'Giao dịch ""%1"". Đơn vị tính theo trình tự của các giao dịch được kiểm soát phải trùng nhau.';
				|ru = 'Операция ""%1"". Единица измерения в последовательности контролируемых операций должна совпадать.';
				|en = 'The ""%1"" operation. The unit of measure in the sequence of controlled operations must match.'; fa = 'The ""%1"" operation. The unit of measure in the sequence of controlled operations must match.';
				|it = 'Operazione ""%1"". L''unità di misura nella sequenza di operazioni controllate deve corrispondere.';
				|pl = 'Operacja ""%1"". Jednostka miary w sekwencji kontrolowanych operacji powinna być zgodna.';
				|tr = '""%1"" işlemi. Kontrollü işlemler sırasındaki ölçü birimi eşleşmelidir.'"));
		ControlMessages.Insert("ControlIndividualOfOperationsInSequence",
			NStr("vi = 'Các thao tác riêng biệt không thể là một phần của chuỗi các thao tác được kiểm soát (""%1"").';
				|ru = 'Идивидуальные операции не могут быть частью последовательностей контролируемых операций (""%1"").';
				|en = 'Individual operations cannot be a part of sequences of controlled operations (""%1"").'; fa = 'Individual operations cannot be a part of sequences of controlled operations (""%1"").';
				|it = 'Individual operations cannot be a part of sequences of controlled operations (""%1"").';
				|pl = 'Individual operations cannot be a part of sequences of controlled operations (""%1"").';
				|tr = 'Özelleştirilmiş işlemler, (""%1"") kontrollü işlem sırasının parçası olamaz.'"));
		
		StructureOfChecks.Insert("ControlOperations", ControlMessages);
		
	EndIf;
	
	If Not IsBlankString(ChecksList) Then
		ChecksArray =  StrSplit(ChecksList, ",");
		For Each KeyAndValue In StructureOfChecks Do
			If ChecksArray.Find(KeyAndValue.Key) = Undefined Then
				StructureOfChecks.Delete(KeyAndValue.Key);
			EndIf;
		EndDo;
	EndIf;
	
	Return StructureOfChecks;
	
EndFunction

// Substitution to control the correctness of control operations
// 
// Returns:
//  String -  Substitution Text
Function TextCorrectnessOfSequenceOfControlOperations() Export
	
	Result = "
	|	MAX(CASE
	|		WHEN CatOperations.Control = VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations)
	|			AND (CatFollowingOperations.Control <> VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations)
	|					AND CatFollowingOperations.Control <> VALUE(Enum.ManufacturingOperationControlOptions.Required2)
	|				OR CatFollowingOperations.Ref IS NULL)
	|			AND ISNULL(CatOperations.Owner.Department.UseManufacturingExecutionSystem, FALSE) = FALSE
	|		THEN TRUE
	|	ELSE FALSE
	|	END) AS ControlSequenceError,
	|	MAX(CASE
	|		WHEN CatOperations.Control = VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations)
	|			AND (CatFollowingOperations.Control = VALUE(Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations)
	|					OR CatFollowingOperations.Control <> VALUE(Enum.ManufacturingOperationControlOptions.Required2))
	|			AND CatOperations.UnitOfMeasure <> CatFollowingOperations.UnitOfMeasure
	|			AND ISNULL(CatOperations.Owner.Department.UseManufacturingExecutionSystem, FALSE) = FALSE
	|		THEN TRUE
	|	ELSE FALSE
	|	END) AS ControlUnitError,
	|	FALSE AS ControlIndividualOfOperationsInSequence,
	|";
	
	Return Result;
	
EndFunction

// Substitution to control the correctness of work planning stages
// 
// Returns:
//  String -  Substitution Text
Function TextWorkPlanningStageIsLastOne() Export
	
	Result = "
	|	MAX(CASE
	|		WHEN CatOperations.WorkPlanning
	|				AND CatOperations.NextOperation = 0
	|		THEN TRUE
	|	ELSE FALSE
	|	END) AS WorkPlanningStageIsLast,
	|";
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region UpdateStageData

// Request parameters resource mapping process stage.
// 
// Returns:
//  Structure - parameter structure
Function RequestParametersResourceMappingProcessStage() Export
	
	Result = New Structure;
	
	Result.Insert("ProcessTechnologyResources");
	
	Result.Insert("Stage");
	Result.Insert("Department");
	Result.Insert("ReferenceOrder");
	
	Result.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	Result.Insert("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	Result.Insert("SupplyOptions", ProductionProcessEditorClientServer.OptionsForSupplyingStageLinesAreNonEditable());
	Result.Insert("EmptyUID", CommonClientServer.BlankUUID());
	
	Result.Insert("UseFinishedProducts", True);
	Result.Insert("UseMaterials",       True);
	Result.Insert("UseLaborCosts",    True);
	
	Return Result;
	
EndFunction

// Table of process resources.
// 
// Returns:
//  ValueTable - Table of Process Resources:
// * TSName - String - 
// * Products - CatalogRef.Products - 
// * Characteristic - CatalogRef.ItemsCharacteristics - 
// * WorkKind - CatalogRef.EmployeeWorkKinds - 
// * Package - CatalogRef.PackagesAndUnitsOfMeasure - 
// * ProductCostElement - CatalogRef.ProductCostElements - 
// * Count - Number - 
Function TableOfProcessResources() Export
	
	Result = New ValueTable;
	
	Result.Columns.Add("TSName", New TypeDescription("String",,,,New StringQualifiers(50)));
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("WorkKind", New TypeDescription("CatalogRef.EmployeeWorkKinds"));
	Result.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Result.Columns.Add("ProductCostElement", New TypeDescription("CatalogRef.ProductCostElements"));
	Result.Columns.Add("Count", New TypeDescription("Number"));
	
	Result.Columns.Add("NameOfTheOperation", New TypeDescription("String",,,,New StringQualifiers(150)));
	Result.Columns.Add("OperationNumber", New TypeDescription("Number"));
	
	Return Result;
	
EndFunction

// Resource mapping table process stage.
// 
// Parameters:
//  QueryOptions - See RequestParametersResourceMappingProcessStage
// 
// Returns:
//  ValueTable - comparison table
Function ResourceComparisonTableProcessStage(QueryOptions) Export
	
	QueryText = ProductionSupply.RequestTextTTMethodsOfGettingMaterialsEmpty() + "
	|
	|SELECT
	|	T.TSName              AS TSName,
	|	T.Products       AS Products,
	|	T.Characteristic     AS Characteristic,
	|	T.WorkKind           AS WorkKind,
	|	T.Package           AS Package,
	|	T.ProductCostElement  AS ProductCostElement,
	|	T.Count         AS Count
	|INTO ProcessTechnologyResources
	|FROM
	|	&ProcessTechnologyResources AS T
	|WHERE
	|	CASE
	|		WHEN T.TSName = ""MaterialsAndServices""
	|			THEN &UseMaterials
	|		WHEN T.TSName = ""ManufacturedProducts""
	|			THEN &UseFinishedProducts
	|		WHEN T.TSName = ""LaborCosts""
	|			THEN &UseLaborCosts
	|		ELSE TRUE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.TSName                                          AS TSName,
	|	MIN(NestedQuery.LineNumber)                           AS LineNumber,
	|	NestedQuery.Products                                   AS Products,
	|	NestedQuery.Characteristic                                 AS Characteristic,
	|	NestedQuery.WorkKind                                       AS WorkKind,
	|	MAX(NestedQuery.CostType)                         AS CostType,
	|	MAX(NestedQuery.ProductCostElement)                     AS ProductCostElement,
	|	CASE
	|		WHEN SUM(NestedQuery.CountStage) > 0 THEN
	|			MAX(NestedQuery.PackagingUnitStage)
	|		ELSE MAX(NestedQuery.PackagingUnitProcessTechnology)
	|	END                                                          AS Package,
	|	SUM(NestedQuery.CountStage)                          AS CountStage,
	|	SUM(NestedQuery.NumberOfTechnicalProcesses)                    AS NumberOfTechnicalProcesses,
	|	SUM(NestedQuery.CannotBeIncreased)                         AS CannotBeIncreased,
	|	SUM(NestedQuery.CannotBeReduced)                         AS CannotBeReduced,
	|
	|	VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide) AS MethodOfReceivingMaterial,
	|	FALSE                                                                        AS WithAssignment
	|
	|INTO MappingTable
	|FROM
	|	(
	|	SELECT
	|		""ManufacturedProducts""                                                AS TSName,
	|		T.LineNumber                                                      AS LineNumber,
	|		T.Products                                                     AS Products,
	|		T.Characteristic                                                   AS Characteristic,
	|		VALUE(Catalog.EmployeeWorkKinds.EmptyRef)             AS WorkKind,
	|		VALUE(Enum.CostTypesOfFinishedProducts.Calculating) AS CostType,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)                AS ProductCostElement,
	|		T.Package                                                         AS PackagingUnitStage,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)         AS PackagingUnitProcessTechnology,
	|		T.Count                                                       AS CountStage,
	|		0                                                                  AS NumberOfTechnicalProcesses,
	|		CASE
	|			WHEN T.Manufactured OR T.Canceled
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeIncreased,
	|		CASE
	|			WHEN T.Manufactured
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeReduced
	|
	|	FROM
	|		Document.ProductionStage2_2.ManufacturedProducts AS T
	|	WHERE
	|		T.Ref = &Stage
	|		AND &UseFinishedProducts
	|	
	|	UNION ALL
	|
	|	SELECT
	|		""ManufacturedProducts""                                                AS TSName,
	|		T.LineNumber                                                      AS LineNumber,
	|		T.Products                                                     AS Products,
	|		T.Characteristic                                                   AS Characteristic,
	|		VALUE(Catalog.EmployeeWorkKinds.EmptyRef)             AS WorkKind,
	|		VALUE(Enum.CostTypesOfFinishedProducts.Fixed)  AS CostType,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)                AS ProductCostElement,
	|		T.Package                                                         AS PackagingUnitStage,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)         AS PackagingUnitProcessTechnology,
	|		T.Count                                                       AS CountStage,
	|		0                                                                  AS NumberOfTechnicalProcesses,
	|		CASE
	|			WHEN T.Manufactured OR T.Canceled
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeIncreased,
	|		CASE
	|			WHEN T.Manufactured
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeReduced
	|	FROM
	|		Document.ProductionStage2_2.SideAndIntermediateRelease AS T
	|	WHERE
	|		T.Ref = &Stage
	|		AND &UseFinishedProducts
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		""MaterialsAndServices""                                               AS TSName,
	|		T.LineNumber                                                      AS LineNumber,
	|		T.Products                                                     AS Products,
	|		T.Characteristic                                                   AS Characteristic,
	|		VALUE(Catalog.EmployeeWorkKinds.EmptyRef)             AS WorkKind,
	|		VALUE(Enum.CostTypesOfFinishedProducts.EmptyRef)   AS CostType,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)                AS ProductCostElement,
	|		T.Package                                                         AS PackagingUnitStage,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)         AS PackagingUnitProcessTechnology,
	|		T.Count                                                       AS CountStage,
	|		0                                                                  AS NumberOfTechnicalProcesses,
	|		CASE
	|			WHEN T.SupplyOption IN (&SupplyOptions)
	|					OR T.CommunicationKeySet <> &EmptyUID
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeIncreased,
	|		CASE
	|			WHEN T.SupplyOption IN (&SupplyOptions)
	|					OR T.Produced
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeReduced
	|	FROM
	|		Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS T
	|	WHERE
	|		T.Ref = &Stage
	|		AND &UseMaterials
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		""LaborCosts""                                                   AS TSName,
	|		T.LineNumber                                                      AS LineNumber,
	|		VALUE(Catalog.Products.EmptyRef)                     AS Products,
	|		VALUE(Catalog.ItemsCharacteristics.EmptyRef)       AS Characteristic,
	|		T.WorkKind                                                         AS WorkKind,
	|		VALUE(Enum.CostTypesOfFinishedProducts.EmptyRef)   AS CostType,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)                AS ProductCostElement,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)         AS PackagingUnitStage,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)         AS PackagingUnitProcessTechnology,
	|		T.Count                                                       AS CountStage,
	|		0                                                                  AS NumberOfTechnicalProcesses,
	|		CASE
	|			WHEN T.Completed2 OR T.Canceled
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeIncreased,
	|		CASE
	|			WHEN T.Completed2
	|				THEN T.Count
	|			ELSE 0
	|		END                                                              AS CannotBeReduced
	|
	|	FROM
	|		Document.ProductionStage2_2.LaborCosts AS T
	|	WHERE
	|		T.Ref = &Stage
	|		AND &UseLaborCosts
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.TSName,
	|		100000,
	|		T.Products,
	|		T.Characteristic,
	|		T.WorkKind,
	|		VALUE(Enum.CostTypesOfFinishedProducts.EmptyRef),
	|		T.ProductCostElement,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		T.Package,
	|		0,
	|		T.Count,
	|		0,
	|		0
	|	FROM
	|		ProcessTechnologyResources AS T
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.TSName,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.WorkKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MappingTable.TSName                                                       AS TSName,
	|	MappingTable.LineNumber                                                 AS LineNumber,
	|	MappingTable.Products.ItemsType                                AS ItemsType,
	|	MappingTable.Products                                                AS Products,
	|	MappingTable.Characteristic                                              AS Characteristic,
	|	MappingTable.WorkKind                                                    AS WorkKind,
	|	MappingTable.CostType                                                AS CostType,
	|	MappingTable.ProductCostElement                                           AS ProductCostElement,
	|
	|	MappingTable.CountStage                                              AS CountStage,
	|	MappingTable.NumberOfTechnicalProcesses                                        AS NumberOfTechnicalProcesses,
	|	ISNULL(MappingTable.Products.UnitOfMeasure,
	|			MappingTable.WorkKind.UnitOfMeasure)                          AS UnitOfMeasure,
	|
	|	MappingTable.CannotBeIncreased                                             AS CannotBeIncreased,
	|	MappingTable.CannotBeReduced                                             AS CannotBeReduced,
	|
	|	MappingTable.CountStage / ISNULL(&PackagingFactor, 1)          AS NumberOfPackagingUnitsStage,
	|	MappingTable.NumberOfTechnicalProcesses / ISNULL(&PackagingFactor, 1)    AS NumberOfPackagingUnitsProcessTechnology,
	|	MappingTable.Package                                                    AS Package,
	|
	|	&WarehouseTextField                                                                  AS Warehouse,
	|	&TextFieldIsSeparate                                                            AS WithAssignment,
	|
	|	MappingTable.CountStage
	|			<> MappingTable.NumberOfTechnicalProcesses                             AS IsChanged
	|
	|FROM
	|	MappingTable AS MappingTable
	|
	|	LEFT JOIN Document.ProductionStage2_2 AS DocumentAttributes
	|	ON DocumentAttributes.Ref = &Stage
	|
	|	,ConnectionTextSoftwareParameters
	|
	|ORDER BY
	|	TSName,
	|	LineNumber";
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"MappingTable.Package",
		"MappingTable.Products");
		
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactor",
		QueryTextPackagingFactor);
	
	ProductionSupply.PerformSubstitutionOfMaterialSupportParameters(QueryText,
		"MappingTable",,
		"&Department",
		Enums.ProductionSupplyFillingVariants.BySupplySchemes);
	
	Query = New Query(QueryText);
	
	For Each KeyAndValue In QueryOptions Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	MappingTable = Query.Execute().Unload();
	
	MappingTable.Columns.Add("Mark", New TypeDescription("Boolean"));
	MappingTable.Columns.Add("Action", New TypeDescription("String", New StringQualifiers(25)));
	MappingTable.Columns.Add("ReadOnly", New TypeDescription("Boolean"));
	MappingTable.Columns.Add("Comment", New TypeDescription("String", New StringQualifiers(50)));
	
	Return MappingTable;
	
EndFunction

#EndRegion

#Region Other

Function ManufacturingProcessStructure(Parameters)
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"CommonModule.ProductionProcessEditor.ManufacturingProcessStructure");
	MeasurementWeight = 0;
	
	ImagesOfElements                    = Undefined;
	BillOfMaterials                         = Parameters["BillOfMaterials"];
	Tree                               = Parameters["ProductionProcessTree"]; // ValueTree
	Result                            = New Structure;
	ArrayOfDivisions                  = New Array;
	
	QueryText = "
	|SELECT
	|	Stages.Description          AS Description,
	|	Stages.Ref                AS Ref,
	|	Stages.ProductionByThirdParty AS ProductionByThirdParty,
	|	Stages.WorkPlanning     AS WorkPlanning,
	|	Stages.StageNumber            AS Number,
	|	Stages.NextStageNo  AS TheNumberOfTheNextOne,
	|	Stages.Department         AS Department
	|FROM
	|	Catalog.ProductionStages AS Stages
	|
	|WHERE
	|	Stages.Owner = &BillOfMaterials
	|	AND NOT Stages.DeletionMark
	|
	|ORDER BY
	|	Stages.StageNumber,
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.Description                                        AS Description,
	|	CAST(Operations.Owner AS Catalog.ProductionStages) AS Stage,
	|	Operations.Ref                                              AS Ref,
	|	Operations.ContainsTechnologicalProcess                      AS ContainsTechnologicalProcess,
	|	Operations.TechnologicalProcess                              AS TechnologicalProcess,
	|	Operations.OperationNumber                                       AS Number,
	|	Operations.NextOperation                              AS TheNumberOfTheNextOne,
	|	Operations.WorkCenter                                        AS WorkCenter,
	|	Operations.Id                                       AS OperationID
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|WHERE
	|	Operations.BillOfMaterials = &BillOfMaterials
	|	AND NOT Operations.DeletionMark
	|	AND &ReadOperations
	|
	|ORDER BY
	|	CAST(Operations.Owner AS Catalog.ProductionStages),
	|	Operations.OperationNumber,
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Operations.Description                                              AS Description,
	|	CAST(Operations.Owner AS Catalog.TechnologicalProcesses) AS TechnologicalProcess,
	|	Operations.Ref                                                    AS Ref,
	|	Operations.OperationNumber                                             AS Number,
	|	Operations.NextOperation                                    AS TheNumberOfTheNextOne,
	|	Operations.WorkCenter                                              AS WorkCenter,
	|	Operations.Id                                             AS OperationID
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|WHERE
	|	Operations.Owner IN (
	|					SELECT
	|						TAOperations.TechnologicalProcess AS TechnologicalProcess
	|					FROM
	|						Catalog.ManufacturingOperations AS TAOperations
	|					WHERE
	|						TAOperations.ContainsTechnologicalProcess
	|						AND TAOperations.BillOfMaterials = &BillOfMaterials
	|						AND NOT TAOperations.DeletionMark)
	|	AND NOT Operations.DeletionMark
	|	AND &ReadOperations
	|
	|ORDER BY
	|	CAST(Operations.Owner AS Catalog.TechnologicalProcesses),
	|	Operations.OperationNumber,
	|	Ref
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	Query.SetParameter("ReadOperations", GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	NumberOfStages          = 0;
	OperationsCount        = 0;
	ThereIsMultioperativeStage = False;
	
	TableStages = QueryResults[0].Unload();
	StageOperationTable = QueryResults[1].Unload();
	TPOperationTable    = QueryResults[2].Unload();
	StageOperationTable.Indexes.Add("Stage");
	TPOperationTable.Indexes.Add("TechnologicalProcess");
	SearchByStage = New Structure("Stage");
	TPSearch    = New Structure("TechnologicalProcess");
	IDLength = Catalogs.ManufacturingOperations.LengthOfOperationID();
	For Each SampleStage In TableStages Do
		
		StageString = Tree.Rows.Add();
		StageString.ItemKind = ProductionProcessEditorClientServer.TypeOfStageElement();
		FillPropertyValues(StageString, SampleStage);
		ProductionProcessEditorClientServer.SetItemImage(StageString, ImagesOfElements);
		
		NumberOfStages = NumberOfStages + 1;
		
		NumberOfStageOperations = 0;
		
		SearchByStage.Stage = SampleStage.Ref;
		StageOperationSelection = StageOperationTable.Copy(SearchByStage);
		For Each SamplingOperation In StageOperationSelection Do
			
			LineOperation = StageString.Rows.Add();
			LineOperation.ItemKind = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
			FillPropertyValues(LineOperation, SamplingOperation);
			
			NumberOfStageOperations = NumberOfStageOperations + 1;
			
			If SamplingOperation.ContainsTechnologicalProcess Then
				
				TPSearch.TechnologicalProcess = LineOperation.TechnologicalProcess;
				SelectingTAOperation = TPOperationTable.Copy(TPSearch);
				For Each SelectionTAOperation In SelectingTAOperation Do
					
					LineOperationTP = LineOperation.Rows.Add();
					LineOperationTP.ItemKind = ProductionProcessEditorClientServer.TypeOfElementOfOperation();
					FillPropertyValues(LineOperationTP, SelectionTAOperation,,"TechnologicalProcess, OperationID");
					LineOperationTP.ReadOnly = True;
					ProductionProcessEditorClientServer.SetItemImage(LineOperationTP, ImagesOfElements);
					LineOperationTP.OperationID = SelectionTAOperation.OperationID
						+ (LineOperation.OperationID * Pow(10, IDLength));
					
					MeasurementWeight = MeasurementWeight + 1;
					
				EndDo;
				LineOperation.TechnologicalProcess = SamplingOperation.TechnologicalProcess;
				
			EndIf;
			ProductionProcessEditorClientServer.SetItemImage(LineOperation, ImagesOfElements);
			
		EndDo;
		
		OperationsCount = OperationsCount + NumberOfStageOperations;
		If NumberOfStageOperations > 1 Then
			ThereIsMultioperativeStage = True;
		EndIf;
		
		If ArrayOfDivisions.Find(StageString.Department) = Undefined Then
			ArrayOfDivisions.Add(StageString.Department);
		EndIf;
	EndDo;
	
	Result.Insert("ProductionProcessTree", Tree);
	Result.Insert("ArrayOfDivisions",           ArrayOfDivisions);
	Result.Insert("StageCount",                NumberOfStages);
	Result.Insert("OperationQuantity",            OperationsCount);
	Result.Insert("ThereIsMultioperativeStage",     ThereIsMultioperativeStage);
	
	MeasurementWeight = MeasurementWeight + NumberOfStages + OperationsCount;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, MeasurementWeight / 1000);
	
	Return Result;
	
EndFunction

Procedure ProcessMessagesToUser(Messages, DataKey = Undefined, SplitLineByLine = False)
	
	If Messages = Undefined Then
		Return;
	EndIf;
	
	CurMessages = New Array;
	
	For Each Message In GetUserMessages(True) Do
		If SplitLineByLine Then
			For Each MessageText In StrSplit(Message.Text, Chars.LF) Do
				NewMessage = New UserMessage();
				FillPropertyValues(NewMessage, Message);
				NewMessage.Text = MessageText;
				NewMessage.DataKey = ?(DataKey <> Undefined, DataKey, NewMessage.DataKey);
				CurMessages.Add(NewMessage);
			EndDo;
		Else
			Message.DataKey = ?(DataKey <> Undefined, DataKey, Message.DataKey);
			CurMessages.Add(Message);
		EndIf;
	EndDo;
	
	CommonClientServer.SupplementArray(Messages, CurMessages);
	
EndProcedure

Procedure AddLayoutSelectionSynchronousLoadingSetupOptionNotFilledIn(Group, TSName)
	
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TSName + ".WorkCenterType");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.Filled;
		
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(TSName + ".SynchronousLoad");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(TSName + ".SetupOptionIsUsed");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TSName + ".SetupSettings");
	ItemFilter.ComparisonType  = DataCompositionComparisonType.NotFilled;
	
EndProcedure

Procedure AddSelectionAndSimultaneousLoading(Group, ObjectName, TSName, MatchingElements)
	
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(TSName + ".SynchronousLoad");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(MatchingElements.ThereIsSynchronousLoad);
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField(ObjectName+".OperatingProcedureOfWorkCenterTypes");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously;
	
EndProcedure

Procedure ReadDetailsOfSetupOption(Object, Form, MatchingElements)
	
	AttributesValues = Catalogs.SetupOptions.SettingOptionDetailsValues(Object.SetupSettings);
	
	For Each KeyAndValue In StructureOfCorrespondenceOfElementsToDetailsOfWorkCenter(MatchingElements) Do
		If AttributesValues.Property(KeyAndValue.Value) Then
			Form[KeyAndValue.Key] = AttributesValues[KeyAndValue.Value];
		EndIf;
	EndDo;
	
EndProcedure

Function StructureOfCorrespondenceOfElementsToDetailsOfWorkCenter(MatchingElements)
	
	Result = New Structure;
	
	Result.Insert(MatchingElements.SetupSettingsAreUsed,           "SetupSettingsAreUsed");
	Result.Insert(MatchingElements.ParallelLoad,                  "ParallelLoad");
	Result.Insert(MatchingElements.WorkTimeOnSynchronousLoad,      "OperationTime");
	Result.Insert(MatchingElements.UnitOfMeasureForSynchronousLoad, "UnitOfMeasure");
	Result.Insert(MatchingElements.UnitOfMeasureOfLoad,              "UnitOfMeasureOfLoad");
	
	Return Result;
	
EndFunction

Procedure AdjustSelectionParameters(ParameterName, ParameterValue, FormItems, TagName)
	
	FormItem = FormItems.Find(TagName);
	If FormItem = Undefined Then
		Return;
	EndIf;
	
	ItemSelectionOptions_ = New Array(FormItem.ChoiceParameters);
	
	IndexOf = 0;
	While IndexOf <= ItemSelectionOptions_.UBound() Do
		ChoiceParameter = ItemSelectionOptions_[IndexOf]; // ChoiceParameter
		If ChoiceParameter.Name = ParameterName Then
			ItemSelectionOptions_.Delete(IndexOf);
		Else
			IndexOf = IndexOf + 1;
		EndIf;
	EndDo;
	
	If ValueIsFilled(ParameterValue) Then
		NewParameter1 = New ChoiceParameter(ParameterName, ParameterValue);
		ItemSelectionOptions_.Add(NewParameter1);
	EndIf;
	
	FormItem.ChoiceParameters = New FixedArray(ItemSelectionOptions_);
	
EndProcedure

// Sets up the elements according to the details of the RC
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	MatchingElements - Structure
Procedure ConfigureVisibilityAccessibilityByRCDetails(Form, MatchingElements)
	
	Items = Form.Items;
	
	ItemsAvailability        = Form[MatchingElements.ItemsAvailability];
	SetupSettingsAreUsed = Form[MatchingElements.SetupSettingsAreUsed];
	ParallelLoad        = Form[MatchingElements.ParallelLoad];
	SynchronousLoad          = Form[MatchingElements.SynchronousLoad];
	
	If ItemsAvailability Then
		Items[MatchingElements.SetupSettings].Enabled = SetupSettingsAreUsed;
	EndIf;
	
	Items[MatchingElements.Load].Visible                 = ParallelLoad;
	Items[MatchingElements.UnitOfMeasureOfLoad].Visible = ParallelLoad;
	
	Items[MatchingElements.TimePerPiece].Visible      = Not SynchronousLoad;
	Items[MatchingElements.TimePerPieceUnitOfMeasure].Visible = Not SynchronousLoad;
	Items[MatchingElements.SetupTime].Visible           = Not SynchronousLoad;
	Items[MatchingElements.SetupTimeUnitOfMeasure].Visible      = Not SynchronousLoad;
	
	Items[MatchingElements.WorkTimeOnSynchronousLoad].Visible      = SynchronousLoad;
	Items[MatchingElements.UnitOfMeasureForSynchronousLoad].Visible = SynchronousLoad;
	
EndProcedure

// A list of data when adding specification resources to process Operation resources.
// 
// Parameters:
//  OperationData - CatalogObject.ManufacturingOperations
// 
// Returns:
//  Array of String
Function ListOfDataWhenAddingResourcesBillOfMaterials(OperationData) Export
	
	Result = New Structure;
	
	If OperationData.OperationNumber = 1 Then
		Result.Insert("MaterialsAndServices", "MaterialsAndServices");
	EndIf;
	
	If OperationData.NextOperation = 0 Then
		Result.Insert("ManufacturedProducts", "RecyclableWaste,ManufacturedProducts");
	EndIf;
	
	Return Result;
	
EndFunction

// Add specification resources to process data
// 
// Parameters:
//  TechProcessData - Structure
//  SpecificationData - See Catalogs.BillsOfMaterials.DataSpecificationConstructor
//  ListOfData - Structure
//  Operation - CatalogRef.ManufacturingOperations
Procedure AddResourcesBillOfMaterials(TechProcessData, SpecificationData, ListOfData, Operation = Undefined) Export
	
	If Not ValueIsFilled(SpecificationData) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In ListOfData Do
		
		TSOfProcessTechnology = KeyAndValue.Key;
		TSArrayBillOfMaterials = StrSplit(KeyAndValue.Value, ",");
		
		Source = Undefined; // ValueTable
		Receiver = Undefined; // ValueTable
		
		For Each TSSpecifications In TSArrayBillOfMaterials Do
			
			If Not SpecificationData.Property(TSSpecifications, Source) Then
				Continue;
			EndIf;
			
			If Not TechProcessData.Property(TSOfProcessTechnology, Receiver) Then
				Receiver = SpecificationData[TSSpecifications].CopyColumns();
				TechProcessData.Insert(TSOfProcessTechnology, Receiver);
			EndIf;
			
			QuantityBeforeAdding = Receiver.Count();
			
			For IndexOf = 0 To Source.Count() - 1 Do
				SourceRow = Source[IndexOf];
				If Not CommonClientServer.HasAttributeOrObjectProperty(SourceRow, "Auxiliary")
						Or Not SourceRow.Auxiliary Then
					DestinationRow = Receiver.Insert(Receiver.Count() - QuantityBeforeAdding);
					FillPropertyValues(DestinationRow, SourceRow);
					If Operation <> Undefined Then
						DestinationRow.Operation = Operation;
					EndIf;
				EndIf;
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion