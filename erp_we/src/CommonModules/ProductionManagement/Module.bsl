////////////////////////////////////////////////////////////////////////////////
// Production Management: Contains procedures for production management.
// The module is part of the "Enterprise Management" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region SubsystemSettings

// Gets the settings of the "inter-Shop management" subsystem"
// 
// Returns:
//   - Structure - production management settings.
//
Function ProductionManagementSettings() Export
	
	SubsystemSettings = New Structure();
	
	ConstantsSet = Constants.CreateSet(
		"ProductionManagementMethod,
		|DynamicStructureOfProductionOrders,
		|UsePlanningByProductionResources,
		|UsePlanningByMaterialResources,
		|UsePlanningIntervalHour");
	ConstantsSet.Read();

	SubsystemSettings.Insert("DynamicStructureOfProductionOrders", ConstantsSet.DynamicStructureOfProductionOrders);
	SubsystemSettings.Insert("TheProductionScheduleIsPlanned", TheProductionScheduleIsUsed(ConstantsSet));
	SubsystemSettings.Insert("PlanningByProductionResourcesIsUsed", ConstantsSet.UsePlanningByProductionResources);
	SubsystemSettings.Insert("PlanningByMaterialResourcesIsUsed", ConstantsSet.UsePlanningByMaterialResources);
	SubsystemSettings.Insert("ScheduleDateFormat", FormatStringForProductionScheduleDate(ConstantsSet));
	SubsystemSettings.Insert("DateFormatOfSchedulePartOfDate", ?(ConstantsSet.UsePlanningIntervalHour, DateFractions.DateTime, DateFractions.Date));
	
	Return SubsystemSettings;
	
EndFunction

// Determines whether work center scheduling is used
// 
// Returns:
//   Boolean - True if work center scheduling is used
//
Function UseWorkCenterWorkPlanning() Export
	
	Return Constants.UseManufacturingExecutionSystem.Get() Or Constants.UseProductionManagement.Get();
	
EndFunction

// Defines the format string for the production schedule date
//
// Parameters:
//  ConstantsSet - ConstantsSet - the values of the constants.
// 
// Returns:
//  String - format string
//
Function FormatStringForProductionScheduleDate(ConstantsSet = Undefined) Export
	
	If ConstantsSet <> Undefined Then
		UsePlanningIntervalHour = ConstantsSet.UsePlanningIntervalHour;
	Else 
		UsePlanningIntervalHour = Constants.UsePlanningIntervalHour.Get();
	EndIf;
	
	If UsePlanningIntervalHour Then
		Result = "DF='dd.MM.yyyy HH:mm'";
	Else
		Result = "DLF=D";
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the option to separate materials in production.
//
// Parameters:
//  BusinessOperation		 - EnumRef.BusinessTransactions, Undefined	 - economic operation
//  DynamicStructure		 - Boolean													 - Indicates that the dynamic structure is used in production orders
// 
// Returns:
//  EnumRef.OptionsOfMaterialAssignmentInProduction - option separation of materials in production.
//
Function OptionOfMaterialAssignmentInProduction(
			BusinessOperation = Undefined,
			DynamicStructure = False) Export
	
	OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.EmptyRef();
	
	// Special logic for the giveaway scheme
	If BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
		
		If Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Get() =
										Enums.AssignmentAtSubcontractingServicesDelivered.ContractWithMaterialProviderForProcessing Then
			OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract;
		Else
			OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts;
		EndIf;
		
	Else
		
		OptionOfAssignment = Constants.OptionOfMaterialAssignmentInProduction.Get();
		
		If OptionOfAssignment.IsEmpty() Then
			OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage;
		EndIf;
		
		// In the dynamic structure, instead of supply for the stages, supply for the order
		//  and distribution of inventory between the stages by priority are used
		If OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage
			And DynamicStructure Then
			OptionOfAssignment = Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder;
		EndIf;
		
	EndIf;
	
	Return OptionOfAssignment;
	
EndFunction

#EndRegion

#Region ProductionOrder

// Adds a conditional design for the Priority field to the list form.
//
// Parameters:
//  Form             - ClientApplicationForm - shape.
//  ListName         - String - name of the dynamic list.
//  FieldName           - String - name of the dynamic list Priority field.
//  TagName       - String - name of the dynamic list Priority column.
//  SelectionIsUsed_ - Boolean - True if the selection is used and you need to set a conditional design for it.
//  FilterFieldName     - String - name of the selection form details.
//  FilterElementName - String - name of the form element to select.
//
Procedure SetConditionalAppearanceOfPriorityField(Form, ListName, FieldName, TagName, SelectionIsUsed_ = False, FilterFieldName = Undefined, FilterElementName = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	
	PresentationOfDesignElement = NStr("vi = 'Mức độ ưu tiên';
										|ru = 'Приоритет';
										|en = 'Priority'; fa = 'اولویت';
										|it = 'Priorità';
										|pl = 'Priorytet';
										|tr = 'Öncelik'");
	For IndexOf = 0 To ConditionalAppearance.Items.Count() - 1 Do
		Item = ConditionalAppearance.Items[0];
		If Item.Presentation = PresentationOfDesignElement Then
			ConditionalAppearance.Items.Delete(Item);
			IndexOf = IndexOf - 1;
		EndIf;
	EndDo;
	
	Query = New Query(
		"SELECT
		|	Priorities.Ref  AS Priority,
		|	Priorities.Color    AS Color
		|FROM
		|	Catalog.Priorities AS Priorities");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			Color = Selection.Color;// ValueStorage
			// Column
			Item = ConditionalAppearance.Items.Add();
			
			Item.Fields.Items.Add().Field = New DataCompositionField(TagName);
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(ListName + "." + FieldName);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Selection.Priority;
			
			Item.Appearance.SetParameterValue("TextColor", Color.Get());
			
			Item.Presentation = PresentationOfDesignElement;
			
			// Filter
			If SelectionIsUsed_ Then
				
				Item = ConditionalAppearance.Items.Add();
				
				Item.Fields.Items.Add().Field = New DataCompositionField(FilterElementName);
				
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = New DataCompositionField(FilterFieldName);
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = Selection.Priority;
				
				Item.Appearance.SetParameterValue("TextColor", Color.Get());
				
				Item.Presentation = PresentationOfDesignElement;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds to the list of conditional registration field of Dataplusvalue
//
//  Parameters:
//   Form - ClientApplicationForm - the form of the document.
//   ListName - String - name of the dynamic list.
//   FieldNameDate - String - conditional form design.
//
Procedure SetConditionalAppearanceOfProductionDateField(Form, ListName = "List", FieldNameDate = "Date") Export
	
	Item = Form.ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(FieldNameDate);

	Item.Appearance.SetParameterValue("Format", FormatStringForProductionScheduleDate());
	
EndProcedure

// Adds conditional formatting to the list form
//
//  Parameters:
//   Form - ClientApplicationForm - the form of the document.
//   ListName - String - name of the dynamic list.
//
Procedure SetConditionalListDesignByOrderStatus(Form, ListName = "List") Export

	// Placing an order with the status "Being formed"
	Item = Form.ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionOrderStatuses2_2.BeingGenerated;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Making a closed order
	Item = Form.ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ProductionOrderStatuses2_2.Closed;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
EndProcedure
#EndRegion

#Region Stages

// Structure of filling in data when changing the status
//
// Parameters:
//  Object                  - DocumentObject.ProductionStage2_2, FormDataStructure - stage.
//  PlannedDateOfReceipt - Date - the planned date of receipt of products.
// 
// Returns:
//   - Structure - fill-in data.
//
Function FillInDataWhenStatusChanges(Object, Val PlannedDateOfReceipt = Undefined) Export
	
	Result = New Structure("EventDate,PlannedDateOfReceipt");
	
	If PlannedDateOfReceipt <> Undefined Then
		Result.PlannedDateOfReceipt = PlannedDateOfReceipt;
	Else
		Result.PlannedDateOfReceipt = Documents.ProductionStage2_2.PlannedDateOfReceipt(Object.Ref);
	EndIf;
		
	Return Result;
	
EndFunction

// Performs the necessary actions with the object when the production stage completion mark changes.
//
// Parameters:
//  Object - DocumentObject.ProductionStage2_2 - Stage
//  FillingData - Structure - see the method of data filling and changing the status().
// 
// Returns:
//  String - contains a list of the details that were changed when the execution mark was changed.
//
Function FillInStageDetailsWhenChangingProgressMark(Object, FillingData = Undefined) Export
	
	StatusIsGenerated = Enums.StatusesOfProductionStages2_2.BeingGenerated;
	GeneratedStatus = Enums.StatusesOfProductionStages2_2.Generated1;
	StatusPending = Enums.StatusesOfProductionStages2_2.ForCompletion;
	StatusStarted       = Enums.StatusesOfProductionStages2_2.Initiated;
	StatusCompleted_1    = Enums.StatusesOfProductionStages2_2.Completed;
	
	ExecutionStarted_    = (Object.ActualStageStart <> '000101010000');
	CompletedExecution = (Object.ActualStageEnd <> '000101010000');
	
	ChangedBankingDetails = "Status";
	
	If CompletedExecution Then
		
		Object.Status = StatusCompleted_1;
		
	ElsIf ExecutionStarted_ 
		And Object.Status = StatusCompleted_1 Then
		
		Object.Status = StatusStarted;
		
	ElsIf ExecutionStarted_ 
		And (Object.Status = StatusIsGenerated
			Or Object.Status = GeneratedStatus
			Or Object.Status = StatusPending) Then
		
		Object.Status = StatusStarted;
		
	ElsIf Not ExecutionStarted_
		And (Object.Status = StatusStarted
			Or Object.Status = StatusCompleted_1) Then
		
		Object.Status = StatusPending;
		
	EndIf;
	
	CompleteStageByStatus(Object, FillingData, ChangedBankingDetails);
	
	Return ChangedBankingDetails;
	
EndFunction

// Performs the actions required when changing the document status
//
// Parameters:
//  Object - DocumentObject.ProductionStage2_2 - Stage
//  StatusBeforeChange - EnumRef.StatusesOfProductionStages2_2 - status before changes
//  FillingData - Structure - see the method of data filling and changing the status().
// 
// Returns:
//  String - contains a list of the details that were changed when the status was changed.
//
Function FillInStageDetailsWhenStatusChanges(Object, StatusBeforeChange, FillingData = Undefined) Export
	
	StatusStarted       = Enums.StatusesOfProductionStages2_2.Initiated;
	StatusCompleted_1    = Enums.StatusesOfProductionStages2_2.Completed;
	
	ChangedBankingDetails = "";
	
	EventDate = Undefined;
	If FillingData <> Undefined Then
		FillingData.Property("EventDate", EventDate);
	EndIf;
	
	If Object.Status <> StatusBeforeChange Then
		
		ChangedBankingDetails = "Status";
		
		ExecutionStarted_ =    (Object.Status = StatusStarted Or Object.Status = StatusCompleted_1);
		CompletedExecution = (Object.Status = StatusCompleted_1);
		
		ChangedBankingDetails = ChangedBankingDetails + ",ActualStageStart,
													 |ActualStageEnd,
													 |StageExecutionIsStarted,
													 |StageIsCompleted,
													 |Completed2";
		
		ProductionManagement.SetDateByMark(
					ExecutionStarted_, 
					Object.ActualStageStart,
					EventDate);
		
		ProductionManagement.SetDateByMark(
					CompletedExecution, 
					Object.ActualStageEnd,
					EventDate,
					CompletedExecution);
		
		CompleteStageByStatus(Object, FillingData, ChangedBankingDetails);
		
	EndIf;
	
	Return ChangedBankingDetails;
	
EndFunction

// Returns parameters for opening the Document form.Stage of production2_2.Form.Farmacoterapeutica.
//
// Parameters:
//  Object					 - DocumentObject.ProductionStage2_2 - stage of production
//  UUID	 - UUID - unique form ID.
// 
// Returns:
//  Structure - parameters of the form of manual placement of the stage in the graph.
//
Function FormParametersForManuallyPlacingStageInGraph(Object, UUID) Export

	FormParameters = New Structure;
	
	// Stage data
	
	FormParameters.Insert("Ref", Object.Ref);
	FormParameters.Insert("Status", Object.Status);
	FormParameters.Insert("ReferenceOrder", Object.ReferenceOrder);
	FormParameters.Insert("Department", Object.Department);
	
	// Production schedule data
	
	FormParameters.Insert("StagePlacementInProductionSchedule", Object.StagePlacementInProductionSchedule);
	FormParameters.Insert("ProductionSchedule");
	
	// Employment of types of work centers
	
	AddressStandards = "";
	AddressEmploymentStructure = "";
	
	If Object.StagePlacementInProductionSchedule
		Or Object.PlanOperationsOfWorkCenterTypes Then
		
		// Standards
		
		WorkCenterTypes = TypesOfWorkCentersUsed(Object);
		
		AddressStandards = PutToTempStorage(WorkCenterTypes, UUID);
		
		// Employment of types of work centers
		
		If Object.StagePlacementInProductionSchedule Then
			
			BusyStage = Object.OccupancyOfWorkCenterTypes.Unload();
			
			VRCArray = TMCommonUse.UnloadColumnValues(BusyStage, "WorkCenterType");
			
		ElsIf Object.PlanOperationsOfWorkCenterTypes Then
			
			BusyStage = AccumulationRegisters.AvailabilityOfWorkCenterTypes.BusyStage(Object.Ref);
			
			If BusyStage.Count() > 0 Then
				VRCArray = TMCommonUse.UnloadColumnValues(BusyStage, "WorkCenterType");
			Else
				VRCArray = TMCommonUse.UnloadColumnValues(WorkCenterTypes, "WorkCenterType");
			EndIf;
			
		EndIf;
		
		BusyStage.GroupBy("WorkCenterType, IntervalDate", "Count");
		BusyStage.Indexes.Add("WorkCenterType, IntervalDate");
		
		EmploymentStructure = New Structure("
				|BusyStage, VRCArray",
				BusyStage,
				VRCArray);
			
		AddressEmploymentStructure = PutToTempStorage(EmploymentStructure, UUID)
		
	EndIf;
	
	FormParameters.Insert("AddressStandards", AddressStandards);
	FormParameters.Insert("AddressEmploymentStructure", AddressEmploymentStructure);
	
	Return FormParameters;

EndFunction

// Forms a representation of the stage, used for formatting fields in the SCD
//
// Parameters:
//  Number				 - 	String - Number
//  StageName	 - 	String - Description
// 
// Returns:
//  String - stage presentation
//
Function PresentationStage(Number, StageName) Export
	
	Return StrTemplate("%1, %2", Number, StageName);
	
EndFunction

#EndRegion

#Region Schedule

// Initiates production schedule planning.
//
// Parameters:
//  PlanningSettings - Structure - schedule planning settings.
//  StorageAddress - UUID, String - the address in the temporary storage
//		where you want to place the planning results.
//
Procedure PlanAndRecordScheduleInBackground(PlanningSettings, StorageAddress) Export
	
	DataProcessors.ProductionSchedulePlanning2_2.PlanAndRecordScheduleInBackground(
		PlanningSettings, StorageAddress);
	
EndProcedure

#EndRegion

#Region Other

// Checks for changes in the table part of the document.
//
// Parameters:
//  DocumentObject		 - DocumentObject	 - document being checked
//  DataBeforeChange	 - Structure		 - structure containing document data before the change
//  TableName			 - String			 - name of the table to check
//  Attributes			 - Array			 - Array of verified Bank details.
// 
// Returns:
//   - Boolean - indicates whether there are changes in the tabular part.
//
Function ChangedTabularPartOfDocument(DocumentObject, DataBeforeChange, TableName, Attributes = Undefined) Export
	
	Result = False;
	
	TableBeforeChange = DataBeforeChange[TableName];// ValueTable -
	
	If Attributes = Undefined Then
		
		Attributes = New Array;
		For Each Column In TableBeforeChange.Columns Do
			Attributes.Add(Column.Name);
		EndDo;
		
	EndIf;
	
	If TableBeforeChange.Count() <> DocumentObject[TableName].Count() Then
		
		Result = True;
		
	Else
		
		For IndexOf = 0 To TableBeforeChange.Count()-1 Do
			
			LineBeforeChange = TableBeforeChange[IndexOf];
			LineAfterChange = DocumentObject[TableName][IndexOf];
			
			For Each Attribute In Attributes Do
				If LineBeforeChange[Attribute] <> LineAfterChange[Attribute] Then
					
					Result = True;
					Break;
					
				EndIf;
			EndDo;
			
			If Result Then
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Checks whether the quantity is filled in correctly in the table part
//
// Parameters:
//  Object - DocumentObject, DataProcessorObjectDataProcessorName - the object that you want to check
//  TSName - String - name of the table part to check
//  NotCheckedAttributeArray - Array - Bank details that must
//		be excluded from the standard verification procedure.
//  Cancel - Boolean - flag for refusing to write an object (perform a specified action).
//
Procedure CheckFillingOfNumberOfWH(Object, TSName, NotCheckedAttributeArray, Cancel) Export
	
	ObjectMetadata = Object.Metadata();
	
	DataKey  = TMCommonUse.DataKeyForMessageToUser(Object);
	DataPath = "Object";
	
	TabularSection = Object[TSName]; // DocumentTabularSection.ProductionOperation2_2.MaterialsAndWorks, DocumentTabularSection.ProductionOperation2_2.ManufacturedProducts - 
	
	NotCheckedAttributeArray.Add(TSName + ".NumberOfPackages");
	NotCheckedAttributeArray.Add(TSName + ".Count");
	
	PresentationOfTS                          = ObjectMetadata.TabularSections[TSName].Synonym;
	PresentationOfPropsNumberOfPackages = ObjectMetadata.TabularSections[TSName].Attributes.NumberOfPackages.Synonym;
	
	TemplateQuantityError = NStr("vi = 'Chưa điền cột ""%ColumnPresentation%"" trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
								|ru = 'Не заполнена колонка ""%ColumnPresentation%"" в строке %LineNumber% списка ""%PresentationOfTS%""';
								|en = 'Column ""%ColumnPresentation%"" in line %LineNumber% of the ""%PresentationOfTS%"" list is not filled in'; fa = 'Column ""%ColumnPresentation%"" in line %LineNumber% of the ""%PresentationOfTS%"" list is not filled in';
								|it = 'Non è compilata la colonna ""%ColumnPresentation%"" nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
								|pl = 'Nie wypełniono kolumny ""%ColumnPresentation%"" w wierszu %LineNumber% listy ""%PresentationOfTS%""';
								|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında ""%ColumnPresentation%"" sütunu doldurulmadı'");
	TemplateQuantityError = StrReplace(TemplateQuantityError, "%PresentationOfTS%", PresentationOfTS);
	TemplateRecalculationError = NStr("vi = 'Đã phát hiện số lượng bằng 0 khi kiểm đếm theo đơn vị lưu kho tại dòng %LineNumber% trong danh sách ""%PresentationOfTS%""';
										|ru = 'Обнаружено нулевое количество при пересчете в единицу хранения в строке %LineNumber% списка ""%PresentationOfTS%""';
										|en = 'Zero quantity is detected when converted to storage unit in line %LineNumber% of list ""%PresentationOfTS%""'; fa = 'Zero quantity is detected when converted to storage unit in line %LineNumber% of list ""%PresentationOfTS%""';
										|it = 'È stata rilevata la quantità pari a zero nel corso di ricalcolo in unità di stoccaggio nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
										|pl = 'Ujawniona jest zerowa ilość podczas przeliczenia do jednostki przechowywania w wierszu %LineNumber% listy ""%PresentationOfTS%""';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında stok ölçü birimine dönüştürülürken sıfır miktar bulundu'");
	TemplateRecalculationError = StrReplace(TemplateRecalculationError, "%PresentationOfTS%", PresentationOfTS);
	
	For Each TabRow In TabularSection Do
		
		If TabRow.Count = 0 
			And TabRow.NumberOfPackages <> 0 Then
			
			MessageText = StrReplace(TemplateRecalculationError, "%LineNumber%", String(TabRow.LineNumber));
			Field = CommonClientServer.PathToTabularSection(TSName, TabRow.LineNumber, "NumberOfPackages");
			
			Common.MessageToUser(MessageText,DataKey,Field,DataPath,Cancel);
			
		ElsIf TabRow.Count = 0 Or TabRow.NumberOfPackages = 0 Then
			
			MessageText = StrReplace(TemplateQuantityError, "%LineNumber%", String(TabRow.LineNumber));
			MessageText = StrReplace(MessageText, "%ColumnPresentation%", PresentationOfPropsNumberOfPackages);
			
			Field = CommonClientServer.PathToTabularSection(TSName, TabRow.LineNumber, "NumberOfPackages");
			
			Common.MessageToUser(MessageText,DataKey,Field,DataPath,Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets the values of the service constants to use the seriynotable Production22
//	and take into account the cost of production Series22 according to the types of nomenclature and policies for accounting for series.
//
Procedure ConfigureUseOfSeriesInProduction22() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	MAX(ItemKinds.KeepAccountingByBatch) AS UseItemsBatchProduction22,
		|	MAX(ISNULL(ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)) AS UseCostAccountingByBatchesProduction22
		|FROM
		|	Catalog.ItemKinds AS ItemKinds
		|
		|HAVING
		|	MAX(ItemKinds.KeepAccountingByBatch) IS NOT NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Constants.UseItemsBatchProduction22 AS UseItemsBatchProduction22,
		|	Constants.UseCostAccountingByBatchesProduction22 AS UseCostAccountingByBatchesProduction22
		|FROM
		|	Constants AS Constants");
	
	BeginTransaction();
	Try
		
		Block = New DataLock();
		
		LockItem = Block.Add("Catalog.ItemKinds");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem = Block.Add("Constant.UseItemsBatchProduction22");
		LockItem.Mode = DataLockMode.Exclusive;
		
		LockItem = Block.Add("Constant.UseCostAccountingByBatchesProduction22");
		LockItem.Mode = DataLockMode.Exclusive;
		
		Block.Lock();
		
		ResultsArray = Query.ExecuteBatch();
		If Not ResultsArray[0].IsEmpty() Then
			
			NewValues = ResultsArray[0].Select();
			NewValues.Next();
		
			PreviousValues1 = ResultsArray[1].Select();
			PreviousValues1.Next();
				
			If NewValues.UseItemsBatchProduction22
				<> PreviousValues1.UseItemsBatchProduction22 Then
				
				Constants.UseItemsBatchProduction22.Set(
					NewValues.UseItemsBatchProduction22);
				
			EndIf;
			
			If NewValues.UseCostAccountingByBatchesProduction22
				<> PreviousValues1.UseCostAccountingByBatchesProduction22 Then
				
				Constants.UseCostAccountingByBatchesProduction22.Set(
					NewValues.UseCostAccountingByBatchesProduction22);
				
			EndIf;
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Template = NStr("vi = 'Không thể đặt giá trị của hằng số ""Sử dụng chuỗi sản phẩm 2.2"" do: %1';
						|ru = 'Не удалось установить значение константы ""Использовать серии номенклатуры производство 2.2"" по причине: %1';
						|en = 'Cannot set value of the ""Use item batch production 2.2"" constant. Reason: %1'; fa = 'Cannot set value of the ""Use item batch production 2.2"" constant. Reason: %1';
						|it = 'Non è possibile stabilire il valore della costante ""Usare le serie della nomenclatura produzione 2.2"" a causa di: %1';
						|pl = 'Nie udało się ustawić wartość konstanty ""Używaj serii pozycji produkcja 2.2"" z powodu: %1';
						|tr = '""Üretim 2.2 ürün partilerini kullan"" sabiti değerinin ayarlanamama nedeni: %1'");
		MessageText = StrTemplate(Template, DetailErrorDescription(ErrorInfo()));
		DefaultLanguageCode = Common.DefaultLanguageCode();
		
		WriteLogEvent(
			NStr("vi = 'Đặt các hằng số ""Sử dụng chuỗi sản xuất mặt hàng 2.2""';
				|ru = 'Установка константы ""Использовать серии номенклатуры производство 2.2""';
				|en = 'Set the ""Use item batch production 2.2"" constant'; fa = 'Set the ""Use item batch production 2.2"" constant';
				|it = 'Impostazione della costante ""Usare le serie della nomenclatura produzione 2.2""';
				|pl = 'Ustanowienie konstanty ""Używaj serii pozycji produkcja 2.2""';
				|tr = '""Üretim 2.2 ürün partilerini kullan"" sabitinin yapılandırılması'", DefaultLanguageCode),
			EventLogLevel.Error,
			Metadata.Constants.UseItemsBatchProduction22,
			,
			MessageText);
		
		Raise;
		
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages
#Region ProductionPlanningProductsWithoutBOM

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_ProductionPlanningProductsWithoutBOM(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.ProductionPlanningProductsWithoutBOM);
	
	NewRow.MultilingualName = "vi = 'Kế hoạch sản xuất không có bảng kê chi tiết các nguồn lực sản xuất';
								|ru = 'Планирование производства продукции без спецификаций';
								|en = 'Plan production of products without BOM';
								|it = 'Pianificazione della produzione dei prodotti senza specifiche';
								|pl = 'Planowanie wytwarzania produkcji bez specyfikacji';
								|tr = 'Ürün reçetesiz ürün üretiminin planlanması'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.ActionDesign = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionManagement.DesignAndPlanningOfProductionWithoutSpecifications");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"ProductionManagement.UseForPlanningProductionOfProductsWithoutSpecifications");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.ProductionOrder2_2.Forms.Queue.FullName());
	FiltersStructure = New Structure();
	FiltersStructure.Insert("ItIsRequiredToCheckStages", True);
	FiltersStructure.Insert("StageGenerationIsRequired", True);
	FiltersStructure.Insert("ProductionProcessType", Enums.ProductionProcessTypes.WithoutBillsOfMaterials);
	NewRow.ActionExecute.FormParameters.Insert("FiltersStructure", FiltersStructure);
	NewRow.ActionExecute.FormParameters.Insert("CheckingClosingOfMonth", True);
EndProcedure

// Stage handlers.

// The procedure determines whether the stage must be completed.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
//
Procedure UseForPlanningProductionOfProductsWithoutSpecifications(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseProduction") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không hạch toán hoạt động sản xuất';
				|ru = 'Учет производственных операций не ведется';
				|en = 'Routing operation accounting is not kept'; fa = 'Routing operation accounting is not kept';
				|it = 'La contabilizzazione delle operazioni di produzione non viene effettuata';
				|pl = 'Ewidencja operacji produkcyjnych nie jest prowadzona';
				|tr = 'Rota işlemleri muhasebesi yapılmamaktadır'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	
	If Not ProductionSettings.ProductionIsUsed22 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không quản lý sản xuất (phiên bản 2.2)';
				|ru = 'Не используется управление производством (версия 2.2)';
				|en = 'Production management, version 2.2 is not used'; fa = 'Production management, version 2.2 is not used';
				|it = 'Gestione della produzione non utilizzata (versione 2.2)';
				|pl = 'Nie jest używane zarządzanie produkcją (wersja 2.2)';
				|tr = 'Üretim yönetimi kullanılmamaktadır (sürüm 2.2)'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	AllowableVariance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving", AllowableVariance);
	
	Query.Text = Documents.ProductionOrder2_2.RequestTextTTUnscheduledOrderProduction();
	Query.Execute();
	
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.UnplannedProductsWithoutSpecifications = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Toàn bộ khối lượng sản xuất cho các đơn đặt hàng mà không có bảng kê chi tiết các nguồn lực sản xuất được lên kế hoạch, hoặc không cần lập kế hoạch.';
				|ru = 'Весь объем производства продукции по заказам без спецификаций запланировано, либо планирование не требуется.';
				|en = 'The whole volume of production by orders without bills of materials is planned or planning is not required.'; fa = 'The whole volume of production by orders without bills of materials is planned or planning is not required.';
				|it = 'Tutto il volume della produzione secondo gli ordini senza specifiche è pianificato, oppure la pianificazione non serve.';
				|pl = 'Cała objętość wytwarzania produkcji wg zamówień bez specyfikacji jest zaplanowana, albo planowanie nie jest wymagane.';
				|tr = 'Ürün reçetesiz siparişler için tüm üretim hacmi planlandı veya planlama gerekmemektedir.'", Common.DefaultLanguageCode()));
		
	EndIf;
	
EndProcedure

// The procedure defines the design of the stage.
//
// Parameters:
//  HandlerParameters - Structure - parameters of the stage event handler.
//
Procedure DesignAndPlanningOfProductionWithoutSpecifications(HandlerParameters) Export
	
	HandlerParameters.Data_Stage.TextExecute = NStr("vi = 'Dự định';
													|ru = 'Запланировать';
													|en = 'To plan'; fa = 'برای برنامه‌ریزی';
													|it = 'Programmare';
													|pl = 'To plan';
													|tr = 'Planla'");
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters);
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfInspectionsAndPlanningOfProductionOfProductsWithoutSpecifications(TableOfChecks) Export
	
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"UnplannedProductsWithoutSpecifications",
		Catalogs.MonthEndClosingOperations.ProductionPlanningProductsWithoutBOM,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"ProductionManagement.VerificationOfNeedForPlanningProductionOfProductsWithoutSpecifications");
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Kế hoạch sản xuất không có bảng kê chi tiết các nguồn lực sản xuất.';
			|ru = 'Планирование производства продукции без спецификаций.';
			|en = 'Plan production of products without BOM.'; fa = 'Plan production of products without BOM.';
			|it = 'Pianificazione della produzione senza specifiche.';
			|pl = 'Planowanie wytwarzania produkcji bez specyfikacji.';
			|tr = 'Ürün reçetesiz ürün üretiminin planlanması.'", Common.DefaultLanguageCode()),
		NStr("vi = 'Nếu một phần của sản phẩm được sản xuất theo đơn đặt hàng sản xuất mà không có bảng kê chi tiết các nguồn lực sản xuất, thì việc sản xuất phần còn lại phải được lên kế hoạch đầy đủ hoặc hủy bỏ.';
			|ru = 'Если по заказу на производство без спецификаций произведена часть продукции, то производство оставшейся части должно быть запланировано в полном объеме, либо отменено.';
			|en = 'If some products are manufactured by production order without bills of materials, the rest of them should be planned for production fully or canceled.'; fa = 'If some products are manufactured by production order without bills of materials, the rest of them should be planned for production fully or canceled.';
			|it = 'Se, su un ordine di produzione senza specifiche, viene prodotta una parte del prodotto, la produzione della parte rimanente deve essere pianificata per intero o annullata.';
			|pl = 'Jeśli zgodnie z zamówieniem na produkcję bez specyfikacji wyprodukowano część produkcji, to wyprodukowanie pozostałej części powinno być zaplanowane w pełnym zakresie, albo odwołane.';
			|tr = 'Ürün reçetesiz üretim emri üzerine ürünlerin bir kısmı üretilirse, kalan kısmın üretimi eksiksiz olarak planlanmalı veya iptal edilmelidir.'", Common.DefaultLanguageCode()));
		
EndProcedure

// The procedure checks for errors during the stage execution and registers them in the IB.
//
// Parameters:
//  CheckParameters - See AuditOfSystemState.InitializeVerificationParameters
//
Procedure VerificationOfNeedForPlanningProductionOfProductsWithoutSpecifications(CheckParameters) Export
	
	FieldList = New ValueList;
	FieldList.Add("Organization",			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Company';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("ProductionOrder",	NStr("vi = 'Đơn hàng sản xuất';
											|ru = 'Заказ на производство';
											|en = 'Production order'; fa = 'سفارش تولید';
											|it = 'Ordine di produzione';
											|pl = 'Zlecenie produkcyjne';
											|tr = 'Üretim emri'", Common.DefaultLanguageCode()));
	FieldList.Add("Products",		NStr("vi = 'Mặt hàng';
											|ru = 'Номенклатура';
											|en = 'Items'; fa = 'اقلام';
											|it = 'Articolo';
											|pl = 'Pozycja';
											|tr = 'Öğe'", Common.DefaultLanguageCode()));
	FieldList.Add("Characteristic",		NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Caratteristica';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'", Common.DefaultLanguageCode()));
	FieldList.Add("Purpose",			NStr("vi = 'Chỉ định';
											|ru = 'Назначение';
											|en = 'Assignment'; fa = 'تخصیص';
											|it = 'Destinazione';
											|pl = 'Przeznaczenie';
											|tr = 'Atama'", Common.DefaultLanguageCode()));
	
	ErrorTemplateText =
		NStr("vi = 'Đơn đặt hàng cho sản xuất không có bảng chi tiết vật liệu đã được phát hiện, theo đó một phần của sản phẩm được sản xuất, và việc sản xuất phần còn lại không được lên kế hoạch. Doanh nghiệp ""%1"", kỳ %2';
			|ru = 'Обнаружены заказы на производство без спецификаций, по которым произведена часть продукции, а производство оставшейся части не запланировано. Организация ""%1"", период %2';
			|en = 'Production orders are found without bills of materials by which some products were manufactured and manufacturing of the rest of the products is not planned. Company %1, period %2'; fa = 'Production orders are found without bills of materials by which some products were manufactured and manufacturing of the rest of the products is not planned. Company %1, period %2';
			|it = 'Trovati ordini per la produzione senza specifiche, per i quali viene prodotta una parte della produzione, e la produzione della parte rimanente non viene pianificata. Organizzazione ""%1"", periodo %2';
			|pl = 'Wykryto zamówienia na produkcję bez specyfikacji, zgodnie z którymi jest wyprodukowana część produkcji, a produkcja części pozostałej nie jest zaplanowana. Firma ""%1"", okres %2';
			|tr = 'Ürünlerin bir kısmının üretildiği ürün reçetesiz üretim emirleri tespit edildi, kalan kısmın ise üretimi planlanmadı. ""%1"" iş yeri, %2 dönemi'", Common.DefaultLanguageCode());
		
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"UnplannedProductsWithoutSpecifications",
		ErrorTemplateText,
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion
#EndRegion

#Region Columns

// Returns a graph of production stages, represented as an adjacency list.
// In the returned table, vertexes are stored as rows in the value table, and edges are stored as the value of one of the columns.
//
// Parameters:
//  FillingData - QueryResult	 - data to fill in the column.
// 
// Returns:
//  ValueTable - A table of values storing the vertices and edges of the graph, with the following columns:
//  * Ref          - CatalogRef, DocumentRef - link to a reference book or document.
//  * Ribs           - Array of DocumentRef, CatalogRef - array of edges.
//  * NumberOfEdges - Number - number of edges.
//
Function Count_(FillingData = Undefined) Export
	
	Types = New Array;
	Types.Add(Catalogs.AllRefsType());
	Types.Add(Documents.AllRefsType());
	
	Count_ = New ValueTable();
	Count_.Columns.Add("Ref",          New TypeDescription(Types));
	Count_.Columns.Add("Ribs",           New TypeDescription("Array"));
	Count_.Columns.Add("NumberOfEdges", New TypeDescription("Number"));
	
	If TypeOf(FillingData) = Type("QueryResult") 
		And Not FillingData.IsEmpty() Then
		
		Vertex = ?(False, New Structure("Ref"), Undefined);
		Selection = FillingData.Select();
		
		While Selection.Next() Do
			
			If Vertex = Undefined
				Or Vertex.Ref <> Selection.Vertex Then
				Vertex = AddVertexToAdjacencyList(Count_, Selection.Vertex);
			EndIf;
			
			If Selection.AdjacentVertex <> null Then
				AddAdjacentVertexToAdjacencyList(Vertex, Selection.AdjacentVertex);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Count_.Indexes.Add("Ref");
	
	Return Count_;
	
EndFunction

// Searches for loops in the graph. the search algorithm 
//  uses non-recursive depth-first traversal of the graph.
//
// Parameters:
//  Count_ - See ProductionManagement.Count_
//  BeginningOfArc - AnyRef - vertex (the beginning of the arc where the cycle is found).
//  EndOfArc - AnyRef - vertex (end of the arc where the cycle is found).
// 
// Returns:
//   - Boolean - True if the loop is found.
//
Function ThereAreCyclesInGraph(Count_, BeginningOfArc = Undefined, EndOfArc = Undefined) Export
	
	If Count_.Count() = 0 Then
		Return False;
	ElsIf Count_.Count() = 1 Then
		Vertex   = Count_[0].Ref;
		ThereAreCycles = Count_[0].Ribs.Find(Vertex) <> Undefined;
		If ThereAreCycles Then
			BeginningOfArc = Vertex;
		EndIf;
		Return ThereAreCycles;
	EndIf;
	
	Count_.Columns.Add("Color", New TypeDescription("Number"));
	Count_.Columns.Add("IndexOfAdjacentVertex", New TypeDescription("Number"));
	Count_.FillValues(-1, "IndexOfAdjacentVertex");
	
	ThereAreCycles = False;
	
	White = 0;
	Gray = 1;
	Black = 2;
	
	Vertex = Count_[0];
	Vertex.Color = Gray;
	
	Stack = New Array; // See ProductionManagement.Count_
	Stack.Add(Vertex);
	
	While Stack.UBound() <> -1 And Not ThereAreCycles Do
		
		Vertex = Stack[0];
		
		If Vertex.IndexOfAdjacentVertex + 1 < Vertex.NumberOfEdges Then
			
			For IndexOf = Vertex.IndexOfAdjacentVertex + 1 To Vertex.NumberOfEdges - 1 Do
				
				Vertex.IndexOfAdjacentVertex = IndexOf;
				
				AdjacentVertex = Count_.Find(Vertex.Ribs[IndexOf], "Ref");
				
				If AdjacentVertex.Color = Gray Then
					
					ThereAreCycles  = True;
					BeginningOfArc = Vertex.Ref;
					EndOfArc  = AdjacentVertex.Ref;
					
					Break;
					
				ElsIf AdjacentVertex.Color = White Then
					
					AdjacentVertex.Color = Gray;
					
					Stack.Insert(0,AdjacentVertex);
					
					Break;
				
				EndIf;
				
			EndDo;
			
		Else
			
			Vertex.Color = Black;
			
			Stack.Delete(0);
			
		EndIf;
		
	EndDo;
	
	Count_.Columns.Delete("Color");
	Count_.Columns.Delete("IndexOfAdjacentVertex");
	
	Return ThereAreCycles;
	
EndFunction

// Returns the environment of the vertex.
//
// Parameters:
//  Vertex - ValueTableRow - a row in the table of values, see the description of the Graph() function. Used columns:
//             * Ref - CatalogRef, DocumentRef - Ref.
//             * Ribs  - Array - ribs.
// 
// Returns:
//   - Array - Vertex environment.
//
Function FindVertexEnvironment(Vertex) Export
	
	Result = New Array;
	
	// Let's add a service field for the algorithm to work
	Vertex.Owner().Columns.Add("Visited", New TypeDescription("Boolean"));
	
	DepthFirstSearch(Vertex, Result);
	
	// Deleting the current vertex
	Result.Delete(Result.Find(Vertex.Ref));
	
	// Delete the service field
	Vertex.Owner().Columns.Delete("Visited");
	
	Return Result;
	
EndFunction

// Performs a depth-first search.
//
// Parameters:
//  Vertex    - ValueTableRow - a row in the table of values, see the description of the Graph() function. Used columns:
//                * Ref   - CatalogRef, DocumentRef - Ref.
//                * Ribs    - Array - ribs.
//                * Visited - Boolean - flag for Visited.
//  Result  - Array - Visited vertexes.
//
Procedure DepthFirstSearch(Vertex, Result) Export
	
	If Vertex.Visited Then
		Return;
	EndIf;
	
	Vertex.Visited = True;
	Result.Add(Vertex.Ref);
	
	For Each Edge In Vertex.Ribs Do
		
		AdjacentVertex = Vertex.Owner().Find(Edge, "Ref");
		DepthFirstSearch(AdjacentVertex, Result);
		
	EndDo;
	
EndProcedure

// Returns the forward direction of the graph traversal"
// 
// Returns:
//   - Number - the direction of traversing the graph "Forward".
//
Function DirectionOfGraphTraversalForward() Export
	
	Return 1;
	
EndFunction

// Returns the direction of traversing the graph " Back"
// 
// Returns:
//   - Number - the direction of traversing the graph "Backwards".
//
Function GraphTraversalDirectionBackwards() Export
	
	Return -1;
	
EndFunction

// Add a vertex to the adjacency list
//
// Parameters:
//  Count_   - See ProductionManagement.Count_
//  Ref - DocumentRef, CatalogRef - link to the vertex.
// 
// Returns:
//  ValueTableRow - top.
//
Function AddVertexToAdjacencyList(Count_, Ref) Export
	
	Vertex = Count_.Add();
	Vertex.Ref = Ref;
	Return Vertex;
	
EndFunction

// Add an adjacent vertex to the adjacency list
//
// Parameters:
//  Vertex	 - ValueTableRow			 - Vertex
//  Ref	 - DocumentRef, CatalogRef	 - a link to an adjacent vertex.
//
Procedure AddAdjacentVertexToAdjacencyList(Vertex, Ref) Export
	
	Vertex.Ribs.Add(Ref);
	Vertex.NumberOfEdges = Vertex.NumberOfEdges + 1;
	
EndProcedure

// Returns the top count of the passed reference, if necessary, the top of the previously created
//
// Parameters:
//  Count_	 - See Count_
//  Ref	 - DocumentRef, CatalogRef	 - object reference.
//  
// Returns:
//  ValueTableRow - top.
//
Function GetVertexOfGraphFromLink(Count_, Ref) Export
	
	Vertex = Count_.Find(Ref, "Ref");
	If Vertex = Undefined Then
		
		Vertex = ProductionManagement.AddVertexToAdjacencyList(Count_, Ref);
		
	EndIf;
	
	Return Vertex;
	
EndFunction

#EndRegion

#Region Stages

// Returns the string that forms the Presentation of the production stage for substitution in the Query Text. 
//   When using a dynamic structure, the Stage field must be of a composite type.
//
// Parameters:
//  DataPath - String - The path to the Stage field
//
// Returns:
//  String - a string to be inserted into the query text.
//
Function QueryTextPresentationStage(DataPath) Export
	
	If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
	
		QueryText =
			"CASE 
			|	WHEN VALUETYPE(&NameOfStageField) = TYPE(Catalog.ProductionStages) THEN
			|		CAST(&NameOfStageField AS Catalog.ProductionStages).Description
			|	WHEN VALUETYPE(&NameOfStageField) = TYPE(Document.ProductionStage2_2) THEN
			|		CAST(&NameOfStageField AS Document.ProductionStage2_2).Number + "", "" + CAST(&NameOfStageField AS Document.ProductionStage2_2).StageName
			|	ELSE
			|		""""
			|END";
	Else
		QueryText = "&NameOfStageField.Number + "", "" + &NameOfStageField.StageName";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&NameOfStageField", DataPath);
	Return QueryText;
	
EndFunction

// Creates a temporary table in the Manager for the VT relationships.
//  Table fields:
//  - Stage
//  - Next step.
//
// Parameters:
//  TempTablesManager	 - TempTablesManager	 - Manager for creating a temporary table
//  TableStages	 - String	 - name of the temporary table that contains the steps for selecting data.
//  StageField		 - String	 - name of the table field.
//  KeyLotReferenceField	 - String	 - name of the table field.
//  ExcludeCompleted	 - Boolean					 - indicates that completed stages should be excluded.
//  InternalConnectionsOnly	 - Boolean					 - indicates that you only need to get internal connections.
//
Procedure CreateVTLinksOfStages(TempTablesManager, TableStages, StageField, KeyLotReferenceField, ExcludeCompleted = False, InternalConnectionsOnly = False) Export
	
	TextsTemporaryTables = New Array();
	CommunicationTexts = New Array();

	If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		If Not InternalConnectionsOnly Then
		
			QueryText =
				"SELECT DISTINCT
				|	Positions.ProductionOrder AS ProductionOrder,
				|	Positions.Products        AS Products,
				|	Positions.Characteristic      AS Characteristic,
				|	Positions.Stage                AS Stage,
				|	Positions.KeyLot          AS KeyLot,
				|	Positions.LineKind           AS LineKind, 
				|	CASE
				|		WHEN Transfers.KeyProducts IS NULL
				|			THEN Positions.KeyProducts
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)
				|			THEN Transfers.ConnectionKeyTransfer
				|		ELSE Transfers.KeyProducts
				|	END                       AS KeyProducts
				|INTO Positions
				|FROM
				|	InformationRegister.OrderStructure AS Positions
				|	
				|		LEFT JOIN InformationRegister.OrderStructure AS Transfers
				|		ON Positions.ProductionOrder = Transfers.ProductionOrder
				|		 AND Positions.Products        = Transfers.Products
				|		 AND Positions.Characteristic      = Transfers.Characteristic
				|		 AND (Positions.KeyProducts   = Transfers.KeyProducts
				|		 	OR Positions.KeyProducts = Transfers.ConnectionKeyTransfer)
				|		 AND NOT Transfers.ConnectionKeyTransfer = &EmptyLinkKey // Moving Party
				|
				|WHERE
				|	(Positions.KeyLot, Positions.Stage) IN
				|		(SELECT
				|			&KeyLotReferenceField,
				|			&StageField
				|		FROM
				|			&TableStages AS T)
				|	AND 	Positions.LineKind IN (
				|			VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
				|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
				|	AND NOT Positions.Stage IN (
				|			UNDEFINED,
				|			VALUE(Catalog.ProductionStages.EmptyRef))
				|
				|INDEX BY
				|	ProductionOrder,
				|	Products,
				|	Characteristic,
				|	KeyProducts";
			TextsTemporaryTables.Add(QueryText);
			
			QueryText =
				"SELECT DISTINCT
				|	CASE 
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) THEN
				|			Positions.Stage
				|		ELSE
				|			RelatedPositions.Stage
				|	END AS Stage,
				|	CASE 
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) THEN
				|			Positions.KeyLot
				|		ELSE
				|			RelatedPositions.KeyLot
				|	END AS KeyLot,
				|	CASE 
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) THEN
				|			RelatedPositions.Stage
				|		ELSE
				|			Positions.Stage
				|	END AS NextStage,
				|	CASE 
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) THEN
				|			RelatedPositions.KeyLot
				|		ELSE
				|			Positions.KeyLot
				|	END AS NextStageIsKeyLotReference
				|FROM
				|	Positions AS Positions
				|	
				|		INNER JOIN InformationRegister.OrderStructure AS RelatedPositions
				|		ON Positions.ProductionOrder = RelatedPositions.ProductionOrder
				|		 AND Positions.Products        = RelatedPositions.Products
				|		 AND Positions.Characteristic      = RelatedPositions.Characteristic
				|		 AND Positions.KeyProducts    = RelatedPositions.KeyProducts
				|		 AND Positions.KeyLot         <> RelatedPositions.KeyLot
				|		 AND RelatedPositions.LineKind IN (
				|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
				|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
				|		AND NOT RelatedPositions.Stage IN (
				|				UNDEFINED,
				|				VALUE(Catalog.ProductionStages.EmptyRef))
				|";
			CommunicationTexts.Add(QueryText);
			
		EndIf;
	
		QueryText =
			"SELECT DISTINCT
			|	CASE
			|		WHEN RelatedStages.StageNumber = ProductionStages.NextStageNo THEN
			|			&StageField
			|		ELSE
			|			RelatedStages.Ref
			|	END AS Stage,
			|	&KeyLotReferenceField AS KeyLot,
			|	CASE 
			|		WHEN RelatedStages.StageNumber = ProductionStages.NextStageNo THEN
			|			RelatedStages.Ref
			|		ELSE
			|			&StageField
			|	END AS NextStage,
			|	&KeyLotReferenceField AS NextStageIsKeyLotReference
			|FROM
			|	&TableStages AS Table
			|	
			|		LEFT JOIN Catalog.ProductionStages AS ProductionStages
			|		ON &StageField = ProductionStages.Ref
			|	
			|		LEFT JOIN Catalog.ProductionStages AS RelatedStages
			|		ON ProductionStages.Owner = RelatedStages.Owner
			|			AND (RelatedStages.NextStageNo = ProductionStages.StageNumber
			|				OR RelatedStages.StageNumber = ProductionStages.NextStageNo)
			|WHERE
			|	RelatedStages.Ref IS NULL OR NOT RelatedStages.DeletionMark";
		CommunicationTexts.Add(QueryText);
	
	EndIf;
	
	QueryText =
		"SELECT DISTINCT
		|	Table.Stage          AS Stage,
		|	CASE
		|		WHEN Table.Stage.DynamicStructure
		|			THEN UUID(Table.Stage.ProductionLot)
		|		ELSE &EmptyLinkKey
		|	END                 AS KeyLot,
		|	Table.NextStage AS NextStage,
		|	CASE
		|		WHEN Table.NextStage.DynamicStructure
		|			THEN UUID(Table.NextStage.ProductionLot)
		|		ELSE &EmptyLinkKey
		|	END                 AS NextStageIsKeyLotReference
		|FROM
		|	QueryTextTTStageConnections AS Table";
		
	QueryText = StrReplace(QueryText, "QueryTextTTStageConnections", "(" + Documents.ProductionStage2_2.QueryTextTTStageConnections() + ")");
	QueryText = StrReplace(QueryText,
		"&ReferencesArrray",
		"SELECT
		|	&StageField
		|FROM
		|	&TableStages AS T");
	CommunicationTexts.Add(QueryText);
	
	If TextsTemporaryTables.Count() > 0 Then
		QueryText = StrConcat(TextsTemporaryTables, TMCommonUse.RequestSeparatorInPacket_()) + TMCommonUse.RequestSeparatorInPacket_();
	Else
		QueryText = "";
	EndIf;
	
	QueryText = QueryText + 
		"SELECT DISTINCT
		|	Table.Stage                    AS Stage,
		|	Table.KeyLot              AS KeyLot,
		|	Table.NextStage           AS NextStage,
		|	Table.NextStageIsKeyLotReference AS NextStageIsKeyLotReference
		|INTO TTCommunicationStages
		|FROM
		|	QueryTextTTStageConnections AS Table
		|
		|INDEX BY
		|	Stage,
		|	NextStage";
	
	QueryText = StrReplace(QueryText, "QueryTextTTStageConnections", "(" + StrConcat(CommunicationTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
	QueryText = StrReplace(QueryText, "&TableStages",   TableStages);
	QueryText = StrReplace(QueryText, "&StageField",       StageField);
	QueryText = StrReplace(QueryText, "&KeyLotReferenceField", KeyLotReferenceField);

	Query = New Query(QueryText);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("ExcludeCompleted", ExcludeCompleted);
	Query.SetParameter("InternalConnectionsOnly", InternalConnectionsOnly);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// Returns the Query Text for forming a table of stage relationships by order. Restriction - links by order are created only for created documents.
//
// Parameters:
//  TemporaryTable		 - Array	 - Query Texts will be added to the array to form temporary tables.
//  InternalConnectionsOnly	 - Boolean	 - True, if the connections need to be received within the Lot reference of production (internal connections).
// 
// Returns:
//  String - Query text
//
Function SubstitutionOfQueryTextOfCommunicationOfStagesByOrder(TemporaryTable, InternalConnectionsOnly = False) Export
	
	CommunicationTexts = New Array();
	
	If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		
		If Not InternalConnectionsOnly Then
		
			QueryText =
				"SELECT DISTINCT
				|	Positions.ProductionOrder AS ProductionOrder,
				|	Positions.Products        AS Products,
				|	Positions.Characteristic      AS Characteristic,
				|	Positions.Stage                AS Stage,
				|	Positions.KeyLot          AS KeyLot,
				|	Positions.LineKind           AS LineKind,
				|	CASE
				|		WHEN Transfers.KeyProducts IS NULL
				|			THEN Positions.KeyProducts
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct)
				|			THEN Transfers.ConnectionKeyTransfer
				|		ELSE Transfers.KeyProducts
				|	END                       AS KeyProducts
				|INTO Positions
				|FROM
				|	InformationRegister.OrderStructure AS Positions
				|	
				|		LEFT JOIN InformationRegister.OrderStructure AS Transfers
				|		ON Positions.ProductionOrder = Transfers.ProductionOrder
				|		 AND Positions.Products        = Transfers.Products
				|		 AND Positions.Characteristic      = Transfers.Characteristic
				|		 AND (Positions.KeyProducts   = Transfers.KeyProducts
				|		 	OR Positions.KeyProducts = Transfers.ConnectionKeyTransfer)
				|		 AND NOT Transfers.ConnectionKeyTransfer = &EmptyLinkKey // Moving Party
				|
				|WHERE
				|	Positions.ProductionOrder = &ReferenceOrder
				|	AND Positions.LineKind IN (
				|			VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
				|			VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
				|	AND NOT Positions.Stage IN (
				|			UNDEFINED,
				|			VALUE(Catalog.ProductionStages.EmptyRef))
				|
				|INDEX BY
				|	ProductionOrder,
				|	Products,
				|	Characteristic,
				|	KeyProducts";
			TemporaryTable.Add(QueryText);
			
			QueryText =
				"SELECT DISTINCT
				|	CASE 
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) THEN
				|			Positions.Stage
				|		ELSE
				|			RelatedPositions.Stage
				|	END AS Stage,
				|	CASE 
				|		WHEN Positions.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct) THEN
				|			RelatedPositions.Stage
				|		ELSE
				|			Positions.Stage
				|	END AS NextStage
				|FROM
				|	Positions AS Positions
				|	
				|		INNER JOIN InformationRegister.OrderStructure AS RelatedPositions
				|		ON Positions.ProductionOrder = RelatedPositions.ProductionOrder
				|		 AND Positions.Products        = RelatedPositions.Products
				|		 AND Positions.Characteristic      = RelatedPositions.Characteristic
				|		 AND Positions.KeyProducts    = RelatedPositions.KeyProducts
				|		 AND Positions.KeyLot         <> RelatedPositions.KeyLot
				|		 AND RelatedPositions.LineKind IN (
				|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
				|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
				|		AND NOT RelatedPositions.Stage IN (
				|				UNDEFINED,
				|				VALUE(Catalog.ProductionStages.EmptyRef))
				|";
			CommunicationTexts.Add(QueryText);
			
		EndIf;
		
		// restriction - links by order are created only for created documents
		
	EndIf;
	
	QueryText = Documents.ProductionStage2_2.QueryTextOfCommunicationOfStagesByOrder();
	CommunicationTexts.Add(QueryText);
	
	QueryText = StrConcat(CommunicationTexts, TMCommonUse.QuerySeparatorInJoin(True));
	Return QueryText;
	
EndFunction

#EndRegion

#Region Schedule

// Plans a production schedule for one or more orders
// and records it as a work schedule.
//
// Parameters:
//  Parameters - Structure - graph calculation parameters, elements:
//		* References - Array of DocumentRef.ProductionOrder2_2 - contains links to orders,
//			the schedule of which needs to be calculated.
//		* FullReplanning - Boolean - flag that the calculation should be performed for all production stages;
//			otherwise, the calculation will only be performed for stages that require recalculation of the schedule.
//		* UseAvailabilityReserve - Boolean - flag that you can use the availability
//			of work center types that is in reserve when planning.
//		* CancelManualChangesOfSchedule - Boolean - flag for canceling
//			manual changes to the production schedule of stages during planning.
//  StorageAddress - String - the address of the repository where the planning result will be placed.
//  	Structure with keys:
//		The quantity of this number is the number of orders, the schedule of which had to be calculated.
//		The number of processed orders is the number of orders whose schedule was calculated successfully.
//		There are errors - A Boolean flag that an error occurred during the planning process of one of the orders.
//		The order is an error - document link.ORDERPRODUCTION2_2 - a link to the order, during the planning
//		 of which errors occurred. The planning of the schedule of orders is carried out sequentially,
//		 in accordance with the priorities of the orders. If the planning of the next order is completed
//		 with errors, then further calculation of the schedule is not performed.
//
Procedure ScheduleOrders(Parameters, StorageAddress) Export
	
	Result = New Structure;
	Result.Insert("TotalCount1", Parameters.References.Count());
	Result.Insert("ProcessedItemsCount", 0);
	Result.Insert("HasErrors", False);
	Result.Insert("ThisIsMistake", Documents.ProductionOrder2_2.EmptyRef());
	
	Selection = OrderSchedulePlanningQueue(Parameters.References);
	
	While Selection.Next() Do
		If Selection.DynamicStructure Then
			PlanningResults = OrderStructureProductionSchedule.CalculateTheSchedule(Selection.Ref, Parameters);
		Else
			PlanningSettings = DataProcessors.ProductionSchedulePlanning2_2.PlanningSettingsWorkingScheduleOfOrders(
				Selection.Ref, Parameters);
			PlanningResults = DataProcessors.ProductionSchedulePlanning2_2.PlanAndRecordSchedule(
				PlanningSettings);
		EndIf;
		
		If ValueIsFilled(PlanningResults.Errors) Then
			Result.HasErrors = True;
			Result.ThisIsMistake = Selection.Ref;
			Break;
		ElsIf PlanningResults.ScheduleIsPlanned Then
			Result.ProcessedItemsCount = Result.ProcessedItemsCount + 1;
		EndIf;
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Plans the schedule in turn for production orders in order of priority
//  and records it as a work schedule.
//
Procedure ScheduleQueueOfProductionOrders() Export
	
	Selection = OrderSchedulePlanningQueue();
	
	While Selection.Next() Do
		If Selection.DynamicStructure Then
			PlanningResults = OrderStructureProductionSchedule.CalculateTheSchedule(Selection.Ref);
		Else
			PlanningSettings = DataProcessors.ProductionSchedulePlanning2_2.PlanningSettingsWorkingScheduleOfOrders(
				Selection.Ref);
			PlanningResults = DataProcessors.ProductionSchedulePlanning2_2.PlanAndRecordSchedule(
				PlanningSettings);
		EndIf;
		
		If ValueIsFilled(PlanningResults.Errors) Then
			WriteLogEvent(
				ProductionServer.EventProductionSchedulePlanning(),
				EventLogLevel.Error,
				Selection.Ref.Metadata(),
				Selection.Ref,
				StrTemplate(NStr("vi = 'Không thể tính tiến độ sản xuất cho đơn hàng: %1, do %2';
								|ru = 'Не удалось рассчитать график производства по заказу: %1, по причине %2';
								|en = 'Cannot create a production schedule for the %1 order. Reason: %2'; fa = 'Cannot create a production schedule for the %1 order. Reason: %2';
								|it = 'Не удалось рассчитать график производства по заказу: %1, по причине %2';
								|pl = 'Nie można obliczyć harmonogramu produkcji dla zamówienia: %1, z powodu %2';
								|tr = 'Sipariş üzerine üretim programı hesaplanamadı: %1, çünkü %2'"),
					Selection.Ref,
					PlanningResults.Errors[0].LongDesc));
		EndIf;
	EndDo;
	
EndProcedure

// Plans a production schedule for a given array of stages.
//
// Parameters:
//  Parameters - Structure - schedule planning parameters with elements:
//		* Stages - Array of DocumentRef.ProductionStage2_2 - links to stages.
//		* UseAvailabilityReserve - Boolean - flag that you can use the availability
//			of work center types that is in reserve when planning.
//		* CancelManualChangesOfSchedule - Boolean - flag for canceling
//			manual changes to the production schedule of stages during planning.
//  StorageAddress - String - address of the storage where the planning result will be placed.
//
Procedure PlanScheduleOfStages(Parameters, StorageAddress) Export
	
	Result = New Structure;
	Result.Insert("TotalCount1", Parameters.Stages.Count());
	Result.Insert("ProcessedItemsCount", 0);
	Result.Insert("HasErrors", False);
	Result.Insert("ThisIsMistake", Documents.ProductionOrder2_2.EmptyRef());
	
	Query = New Query(
		"SELECT
		|	Stages.ReferenceOrder AS ReferenceOrder,
		|	Stages.Ref       AS Ref
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|WHERE
		|	Stages.Ref IN (&References)
		|	AND Stages.Posted
		|	AND Stages.Status IN (
		|		VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
		|		VALUE(Enum.StatusesOfProductionStages2_2.Generated1),
		|		VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion))
		|	AND NOT Stages.DynamicStructure
		|
		|ORDER BY
		|	Stages.ReferenceOrder.Priority.AddlOrderingAttribute,
		|	Stages.ReferenceOrder.Department.AddlOrderingAttribute,
		|	Stages.ReferenceOrder.Queue
		|
		|TOTALS BY
		|	ReferenceOrder");
	Query.SetParameter("References", Parameters.Stages);
	Tree = Query.Execute().Unload(QueryResultIteration.ByGroups);
	
	For Each CommandLine_ In Tree.Rows Do
		References = CommandLine_.Rows.UnloadColumn("Ref");
		
		PlanningSettings = DataProcessors.ProductionSchedulePlanning2_2.PlanningSettingsWorkingScheduleOfStages(
			CommandLine_.ReferenceOrder, References, Parameters);
		PlanningResults = DataProcessors.ProductionSchedulePlanning2_2.PlanAndRecordSchedule(
			PlanningSettings);
		
		If ValueIsFilled(PlanningResults.Errors) Then
			Result.HasErrors = True;
			Result.ThisIsMistake = CommandLine_.ReferenceOrder;
		Else
			Result.ProcessedItemsCount = Result.ProcessedItemsCount + References.Count();
		EndIf;
	EndDo;
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

// Performs "online" calculation of the terms of providing the stages with materials for the task of calculating the production schedule.
//
// Parameters:
//  ReferenceOrder - DocumentRef.ProductionOrder2_2 - the order for which you need to get the restrictions.
// 
// Returns:
//  ValueTable, Undefined - table with columns:
//		* ProductionStage - DocumentRef.ProductionStage2_2 - stage.
//		* SupplyDate - Date - date of providing the stage with materials.
//	If the materials provided are not available, it is returned indefinitely.
//
Function CalculateProductionScheduleConstraintsOnMaterials(ReferenceOrder) Export
	
	Query = New Query(
		"SELECT
		|	ProductionStages.Ref AS Ref
		|FROM
		|	Document.ProductionStage2_2 AS ProductionStages
		|WHERE
		|	ProductionStages.ReferenceOrder = &ReferenceOrder
		|		AND ProductionStages.Posted
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentOrderDocument.Priority.AddlOrderingAttribute AS Priority
		|FROM
		|	Document.ProductionOrder2_2 AS DocumentOrderDocument
		|WHERE
		|	DocumentOrderDocument.Ref = &ReferenceOrder");
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	ResultsPackage = Query.ExecuteBatch();
	ArrayOfStages = ResultsPackage[0].Unload().UnloadColumn("Ref");
	OrderPriority = ResultsPackage[1].Unload()[0].Priority;
	
	TempTablesManager = New TempTablesManager;
	InventoryAllocation.AllocationOfInventoryToOrdersInSelectedQueue(
		ArrayOfStages,
		OrderPriority,
		TempTablesManager);
		
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BeginningOfThisDay", BegOfDay(CurrentSessionDate()));
	
	QueryText =
		"SELECT
		|	Set.ProductionStage AS ProductionStage,
		|	MAX(Set.SupplyDate) AS SupplyDate
		|FROM(
		|	SELECT
		|		Table.ShipmentOrder AS ProductionStage,
		|		CalculationOfDeliveryDateOverridable.PlannedDeliveryDate AS SupplyDate
		|	FROM
		|		TTDistribution AS Table
		|			
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|	WHERE
		|		Table.InventoryState IN(
		|			VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|			VALUE(Enum.InventoryStates.NotProvided))
		|		AND Table.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply))
		|		AND CalculationOfDeliveryDateOverridable.PlannedDeliveryDate > &BeginningOfThisDay
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Table.ShipmentOrder AS ProductionStage,
		|		CASE 
		|			WHEN NOT (Table.ReceiptOrder REFS Document.ProductionStage2_2
		|				AND CAST(Table.ShipmentOrder AS Document.ProductionStage2_2).ReferenceOrder
		|					= CAST(Table.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder)
		|				THEN Table.AvailabilityDate
		|			ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|		END AS SupplyDate
		|	FROM
		|		TTDistribution AS Table
		|		
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|	WHERE
		|		Table.InventoryState IN(
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|				VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|				VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|			AND Table.AvailabilityDate > &BeginningOfThisDay
		|			AND NOT TRUE IN
		|				(
		|					SELECT
		|						TOP 1 TRUE
		|					FROM
		|						Document.ProductionStage2_2.ManufacturedProducts AS Products_1
		|					WHERE
		|						Products_1.Ref = Table.ReceiptOrder
		|						AND Products_1.StageConsumer = Table.ShipmentOrder
		|						AND NOT Products_1.Canceled
		|						AND NOT Products_1.ToExpenseAs)
		|			AND NOT TRUE IN
		|				(
		|					SELECT
		|						TOP 1 TRUE
		|					FROM
		|						Document.ProductionStage2_2.SideAndIntermediateRelease AS Products_1
		|					WHERE
		|						Products_1.Ref = Table.ReceiptOrder
		|						AND Products_1.StageConsumer = Table.ShipmentOrder
		|						AND NOT Products_1.Canceled
		|						AND NOT Products_1.ToExpenseAs)) AS Set
		|GROUP BY
		|	Set.ProductionStage";
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfMainMethodOfProviding(
		"Table.Products",
		"Table.Characteristic",
		"Table.Warehouse",
		"TRUE");
	
	QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE",
		Substitutions.Joins);
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
		Substitutions.Field,
		"&BeginningOfThisDay",
		"Table.Products",
		"Table.Warehouse");
	
	QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE",
		Substitutions.Joins);
	
	Texts = New Array();
	TemporaryTableText = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	Texts.Add(TemporaryTableText);
	Texts.Add(QueryText);
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// According to the production schedule, it checks that the condition is met: the sequence stage
// begins after the predecessor stage. By followers/predecessors, we mean
// both the stages of one chain that are directly connected, and the stages of different chains
// that are connected through assignments. Stages for which the condition is not met are marked as requiring recalculation.
//
// Parameters:
//  Stages - DocumentRef.ProductionStage2_2, Array - the steps that need to be checked.
//
Procedure CheckOrderOfSteps(Stages) Export
	
	TempTablesManager = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Stages", Stages);
	Query.SetParameter("ScheduleStatus", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("Backward", Enums.WayOfLinkingProductionOperations.Backward);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text = 
	"SELECT
	|	Stages.Ref AS Stage,
	|	CASE
	|		WHEN Stages.DynamicStructure
	|			THEN UUID(Stages.ProductionLot)
	|		ELSE &EmptyLinkKey
	|	END        AS KeyLot
	|INTO TTStages
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|WHERE
	|	Stages.Ref IN (&Stages)
	|
	|INDEX BY
	|	Stage,
	|	KeyLot";
	Query.Execute();
	
	CreateVTLinksOfStages(TempTablesManager, "TTStages", "Stage", "KeyLot", True);
	
	BatchQueryText = New Array;
	
	QueryText =
	"SELECT
	|	TTCommunicationStages.Stage       AS Stage,
	|	TTCommunicationStages.KeyLot AS KeyLot
	|INTO TTAllStages
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|
	|UNION
	|
	|SELECT
	|	TTCommunicationStages.NextStage           AS Stage,
	|	TTCommunicationStages.NextStageIsKeyLotReference AS KeyLot
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|
	|INDEX BY
	|	Stage,
	|	KeyLot";
	BatchQueryText.Add(QueryText);
	
	QueryText = InformationRegisters.ScheduleOfProductionStages2_2.QueryTextTTTermsOfStages(
		"TTAllStages", "Stage", "KeyLot");
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	TTCommunicationStages.Stage                                   AS Stage,
	|	TTCommunicationStages.KeyLot                             AS KeyLot,
	|	StageSchedule.ProductionOrder                      AS ProductionOrder,
	|	ISNULL(StageDocument.DynamicStructure, TRUE) AS DynamicStructure,
	|	CASE
	|		WHEN StageDocument.Ref IS NULL
	|			THEN TRUE
	|		ELSE StageDocument.ReferenceOrder.ProductionScheduling = &Backward
	|	END                                                AS Backward,
	|	CASE
	|		WHEN StageDocument.Ref IS NULL
	|			THEN TRUE
	|		ELSE NOT StageDocument.StagePlacementInProductionSchedule
	|				AND StageDocument.Status IN (
	|					VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
	|					VALUE(Enum.StatusesOfProductionStages2_2.Generated1),
	|					VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion))
	|	END                                                AS YouCanPlan,
	|	
	|	TTCommunicationStages.NextStage                                   AS NextStage,
	|	TTCommunicationStages.NextStageIsKeyLotReference                         AS NextStageIsKeyLotReference,
	|	NextStageSchedule.ProductionOrder                     AS NextStageIsProductionOrder,
	|	ISNULL(NextStageIsDocument.DynamicStructure, TRUE) AS NextStageIsDynamicStructure,
	|	CASE
	|		WHEN NextStageIsDocument.Ref IS NULL
	|			THEN TRUE
	|		ELSE NextStageIsDocument.ReferenceOrder.ProductionScheduling = &Backward
	|	END                                                         AS NextStageToBeginning,
	|	CASE
	|		WHEN NextStageIsDocument.Ref IS NULL
	|			THEN TRUE
	|		ELSE NOT NextStageIsDocument.StagePlacementInProductionSchedule
	|				AND NextStageIsDocument.Status IN (
	|					VALUE(Enum.StatusesOfProductionStages2_2.BeingGenerated),
	|					VALUE(Enum.StatusesOfProductionStages2_2.Generated1),
	|					VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion))
	|	END                                                         AS NextStageCanBePlanned
	|INTO TTDueToViolation
	|FROM
	|	TTCommunicationStages AS TTCommunicationStages
	|	
	|	INNER JOIN TTTermsOfStages AS StageSchedule
	|	ON TTCommunicationStages.Stage = StageSchedule.ProductionStage
	|		AND TTCommunicationStages.KeyLot = StageSchedule.KeyLot
	|	
	|	INNER JOIN TTTermsOfStages AS NextStageSchedule
	|	ON TTCommunicationStages.NextStage = NextStageSchedule.ProductionStage
	|		AND TTCommunicationStages.NextStageIsKeyLotReference = NextStageSchedule.KeyLot
	|	
	|	LEFT JOIN Document.ProductionStage2_2 AS StageDocument
	|	ON TTCommunicationStages.Stage = StageDocument.Ref
	|	
	|	LEFT JOIN Document.ProductionStage2_2 AS NextStageIsDocument
	|	ON TTCommunicationStages.NextStage = NextStageIsDocument.Ref
	|WHERE
	|	StageSchedule.StageEnd > NextStageSchedule.StageStart
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Links.NextStageIsProductionOrder AS ProductionOrder,
	|	Links.NextStage                    AS ProductionStage,
	|	Links.NextStageIsKeyLotReference          AS KeyLot
	|FROM
	|	TTDueToViolation AS Links
	|WHERE
	|	Links.NextStageIsDynamicStructure
	|	AND Links.NextStageCanBePlanned
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Links.NextStage AS Stage
	|FROM
	|	TTDueToViolation AS Links
	|WHERE
	|	NOT Links.NextStageIsDynamicStructure
	|	AND Links.NextStageCanBePlanned
	|	AND Links.NextStageToBeginning
	|
	|UNION ALL
	|
	|SELECT
	|	Links.Stage AS Stage
	|FROM
	|	TTDueToViolation AS Links
	|WHERE
	|	NOT Links.DynamicStructure
	|	AND Links.YouCanPlan
	|	AND NOT Links.Backward";
	BatchQueryText.Add(QueryText);
	
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";
	
	Query.Text = StrConcat(BatchQueryText, Separator);
	QueryResults = Query.ExecuteBatch();
	
	Jobs = QueryResults[QueryResults.UBound() - 1].Unload();
	If Jobs.Count() > 0 Then
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(Jobs);
	EndIf;
	
	StepsToRecalculate = QueryResults[QueryResults.UBound()].Unload().UnloadColumn("Stage");
	If StepsToRecalculate.Count() > 0 Then
		InformationRegisters.JobsToProductionScheduleCalculation.AddTasks(StepsToRecalculate);
	EndIf;
	
EndProcedure

// According to the production schedule, it checks compliance with the condition: the date of providing materials is 
// earlier than the start date of the stages according to the schedule. Stages for which the condition is not met are marked as requiring recalculation.
//
// Parameters:
//  Stages - Array - contains links to documents whose security date may have changed.
//
Procedure CheckTimingOfProvisionOfStages(Stages) Export
	
	If Stages.Count() = 0 
		Or Not ProductionManagementCached.TheProductionScheduleIsUsed() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	TempTablesManager = New TempTablesManager;
	CreateTTProductionScheduleConstraintsOnMaterials(
		TempTablesManager,
		Stages,
		False,
		True);
	
	Query = New Query(
		"SELECT DISTINCT
		|	Supply.ProductionStage               AS ProductionStage,
		|	Supply.StageOfProductionProviding AS ProductionStageInitiator
		|FROM
		|	TTProductionScheduleRestrictionsOnMaterials AS Supply
		|
		|		INNER JOIN Document.ProductionStage2_2 AS Stages
		|		ON Supply.ProductionStage = Stages.Ref
		|
		|		INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON Stages.ReferenceOrder = Schedule.ProductionOrder
		|			AND Stages.Ref = Schedule.Stage
		|			AND Schedule.ScheduleStatus = &WorkingSchedule
		|WHERE
		|	Schedule.Begin < Supply.AvailabilityDate");
	
	Query.SetParameter("WorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.TempTablesManager = TempTablesManager;
	
	OtherStages = Query.Execute().Unload();
	
	If OtherStages.Count() > 0 Then
		InformationRegisters.JobsToProductionScheduleCalculation.AddTasksWithInitiators(OtherStages);
	EndIf;
	
EndProcedure

// Creates a temporary table containing the dates when the production stages are provided with materials.
// Only materials that limit the stages in the production schedule are taken into account.
//
// Parameters:
//  TempTablesManager - TempTablesManager - the Manager where the temporary table will be created.
//  Stages - Array - links to the milestones that you need to get the security dates for.
//  ByProductCategory - Boolean - if True, the dates are obtained in the context of the materials.
//  InContextOfProvidingStages - Boolean - if True, the dates are obtained in the context
//		of the main stages of production. Supporting documents of other types are collapsed.
//
Procedure CreateTTProductionScheduleConstraintsOnMaterials(TempTablesManager, Stages, ByProductCategory, InContextOfProvidingStages) Export
	
	QueryText =
		"SELECT
		|	&Fields_Selection,
		|	MAX(
		|				CASE
		|					WHEN Supply.InventoryState IN(
		|							VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|						AND NOT (Supply.ReceiptOrder REFS Document.ProductionStage2_2
		|								AND CAST(Supply.ShipmentOrder AS Document.ProductionStage2_2).ReferenceOrder
		|									= CAST(Supply.ReceiptOrder AS Document.ProductionStage2_2).ReferenceOrder)
		|						THEN
		|							CASE
		|								WHEN Supply.AvailabilityDate < &CurrentDayStart 
		|									THEN &CurrentDayStart
		|								ELSE Supply.AvailabilityDate
		|							END
		|					ELSE CalculationOfDeliveryDateOverridable.PlannedDeliveryDate
		|				END) AS AvailabilityDate
		|INTO TTProductionScheduleRestrictionsOnMaterials
		|FROM
		|	InformationRegister.InventoryAllocation AS Supply
		|		
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|WHERE
		|	Supply.ShipmentOrder IN(&Stages)
		|	AND Supply.InventoryState IN(
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|		VALUE(Enum.InventoryStates.NotProvided))
		|	AND Supply.DemandCharacteristic IN(
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|		VALUE(Enum.DemandCharacteristics.ToSupply))
		|	AND NOT TRUE IN
		|		(
		|			SELECT
		|				TOP 1 TRUE
		|			FROM
		|				Document.ProductionStage2_2.ManufacturedProducts AS Products_1
		|			WHERE
		|				Products_1.Ref = Supply.ReceiptOrder
		|				AND Products_1.StageConsumer = Supply.ShipmentOrder
		|				AND NOT Products_1.Canceled
		|				AND NOT Products_1.ToExpenseAs)
		|	AND NOT TRUE IN
		|		(
		|			SELECT
		|				TOP 1 TRUE
		|			FROM
		|				Document.ProductionStage2_2.SideAndIntermediateRelease AS Products_1
		|			WHERE
		|				Products_1.Ref = Supply.ReceiptOrder
		|				AND Products_1.StageConsumer = Supply.ShipmentOrder
		|				AND NOT Products_1.Canceled
		|				AND NOT Products_1.ToExpenseAs)
		|
		|GROUP BY
		|	&FieldsGroup";
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfMainMethodOfProviding(
		"Supply.Products",
		"Supply.Characteristic",
		"Supply.Warehouse",
		"TRUE");
	
	QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE",
		Substitutions.Joins);
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
		Substitutions.Field,
		"&CurrentDayStart",
		"Supply.Products",
		"Supply.Warehouse");
	
	QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE",
		Substitutions.Joins);
	
	// Substituting selection fields
	Substitution = "Supply.ShipmentOrder AS ProductionStage";
	If ByProductCategory Then
		Substitution = Substitution + ",
			|	Supply.Products    AS Products,
			|	Supply.Characteristic  AS Characteristic";
	EndIf;
	If InContextOfProvidingStages Then
		Substitution = Substitution + ",
			|	CASE
			|		WHEN Supply.ReceiptOrder REFS Document.ProductionStage2_2
			|			THEN Supply.ReceiptOrder
			|		ELSE VALUE(Document.ProductionStage2_2.EmptyRef)
			|	END AS StageOfProductionProviding";
	EndIf;
	QueryText = StrReplace(QueryText, "&Fields_Selection", Substitution);
	
	// Substitution of grouping fields
	Substitution = "Supply.ShipmentOrder";
	If ByProductCategory Then
		Substitution = Substitution + ",
			|	Supply.Products,
			|	Supply.Characteristic";
	EndIf;
	If InContextOfProvidingStages Then
		Substitution = Substitution + ",
			|	CASE
			|		WHEN Supply.ReceiptOrder REFS Document.ProductionStage2_2
			|			THEN Supply.ReceiptOrder
			|		ELSE VALUE(Document.ProductionStage2_2.EmptyRef)
			|	END";
	EndIf;
	QueryText = StrReplace(QueryText, "&FieldsGroup", Substitution);
	
	Texts = New Array();
	TemporaryTableText = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	Texts.Add(TemporaryTableText);
	Texts.Add(QueryText);
	Texts.Add("DROP YearsOfEnterpriseSchedule");
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Stages", Stages);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	
	Query.Execute();
	
EndProcedure

// Creates a temp table containing the dates of the production stages.
//
// Parameters:
//  TempTablesManager				 - TempTablesManager	 - temp table manager, a temp table will be created in it.
//  GettingCondition					 - String, Structure		 - a list of parameters or an arbitrary text for selecting lines in the order structure.
//  ByProductCategory				 - Boolean					 - if True, the dates are obtained in the context of the nomenclature.
//  ExcludeProductionScheduleData	 - Boolean					 - if True, then the production schedule data on the planned Lot references of production should be excluded from the calculation.
//  ScheduleStatus						 - Number					 - See InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule()
//
Procedure CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(TempTablesManager, GettingCondition, ByProductCategory, ExcludeProductionScheduleData, ScheduleStatus = 0) Export
	
	Texts = New Array();
	
	QueryText =
		"SELECT
		|	NestedQuery.Products        AS Products,
		|	NestedQuery.Characteristic      AS Characteristic,
		|	NestedQuery.Warehouse               AS Warehouse,
		|	NestedQuery.Purpose          AS Purpose,
		|	NestedQuery.ProductionOrder AS ProductionOrder,
		|	NestedQuery.KeyProducts    AS KeyProducts,
		|	MAX(CASE
		|			WHEN NestedQuery.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|				THEN NestedQuery.KeyLot
		|		END) AS KeyLot,
		|	MAX(CASE
		|			WHEN NestedQuery.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|				THEN NestedQuery.Stage
		|		END) AS Stage,
		|	SUM(NestedQuery.Required2
		|			- NestedQuery.Scheduled - NestedQuery.AllocatedInFreeProductionLots - NestedQuery.AllocatedInAssignedProductionLots
		|			- CASE
		|				WHEN NestedQuery.ReceiptOrder = UNDEFINED OR NestedQuery.SupplyDate <> DATETIME(1,1,1)
		|					THEN NestedQuery.AllocatedFromAvailableInventory + NestedQuery.AllocatedFromAvailableInventoryWithAssignment
		|				ELSE 0
		|		 END) AS ToSupply,
		|	CASE
		|		WHEN MAX(NestedQuery.SupplyDate) < &CurrentDayStart
		|			THEN
		|				&CurrentDayStart
		|			ELSE
		|				MAX(NestedQuery.SupplyDate)
		|	END AS SupplyDate,
		|	CASE
		|		WHEN MAX(NestedQuery.AvailabilityDate) < &BeginningOfNextDay
		|			THEN
		|				&BeginningOfNextDay
		|			ELSE
		|				MAX(NestedQuery.AvailabilityDate)
		|	END AS AvailabilityDate
		|INTO OrderStructureSupplyOfOrders
		|FROM
		|	(SELECT
		|		OrderStructure.Products        AS Products,
		|		OrderStructure.Characteristic      AS Characteristic,
		|		OrderStructure.Warehouse               AS Warehouse,
		|		OrderStructure.Purpose          AS Purpose,
		|		OrderStructure.ProductionOrder AS ProductionOrder,
		|		OrderStructure.KeyProducts    AS KeyProducts,
		|		OrderStructure.KeyLot          AS KeyLot,
		|		OrderStructure.LineKind           AS LineKind,
		|		OrderStructure.ReceiptOrder  AS ReceiptOrder,
		|		MAX(OrderStructure.Stage)      AS Stage,
		|		CASE
		|			WHEN NOT Schedule.Stage IS NULL THEN
		|				Schedule.Ending
		|			ELSE
		|				OrderStructure.DateOfReceipt
		|		END AS SupplyDate,
		|		CASE
		|			WHEN NOT Schedule.Stage IS NULL THEN
		|				Schedule.Ending
		|			ELSE
		|				CASE
		|					WHEN OrderStructure.DateOfReceipt <> DATETIME(1,1,1) THEN
		|						DATEADD(BEGINOFPERIOD(OrderStructure.DateOfReceipt, DAY), DAY, 1)
		|					ELSE
		|						DATETIME(1,1,1)
		|			END
		|		END AS AvailabilityDate,
		|		SUM(OrderStructure.ToSupply - OrderStructure.Replaced) AS Required2,
		|		SUM(OrderStructure.Scheduled)                    AS Scheduled,
		|		SUM(OrderStructure.AllocatedInFreeProductionLots)             AS AllocatedInFreeProductionLots,
		|		SUM(OrderStructure.AllocatedInAssignedProductionLots)  AS AllocatedInAssignedProductionLots,
		|		SUM(OrderStructure.AllocatedFromAvailableInventory)            AS AllocatedFromAvailableInventory,
		|		SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) AS AllocatedFromAvailableInventoryWithAssignment
		|	FROM
		|		InformationRegister.OrderStructure AS OrderStructure
		|	
		|			LEFT JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|			ON OrderStructure.ProductionOrder = Schedule.ProductionOrder
		|				AND Schedule.ScheduleStatus             = &ScheduleStatus
		|				AND OrderStructure.Stage             = Schedule.Stage
		|				AND OrderStructure.KeyLot       = Schedule.KeyLot
		|				AND OrderStructure.LineKind IN (
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.Move),
		|					VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureSemiFinishedProduct))
		|				AND NOT &ExcludeProductionScheduleData
		|	
		|	WHERE
		|		&GettingCondition
		|			AND OrderStructure.LineKind NOT IN (
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct),
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.ManufactureOfProducts),
		|				VALUE(Enum.KindsOfProductionOrderStructureLines.Disassembly))
		|	
		|	GROUP BY
		|		OrderStructure.Products,
		|		OrderStructure.Characteristic,
		|		OrderStructure.Warehouse,
		|		OrderStructure.Purpose,
		|		OrderStructure.ProductionOrder,
		|		OrderStructure.KeyProducts,
		|		OrderStructure.KeyLot,
		|		OrderStructure.LineKind,
		|		OrderStructure.ReceiptOrder,
		|		CASE
		|			WHEN NOT Schedule.Stage IS NULL THEN
		|				Schedule.Ending
		|			ELSE
		|				OrderStructure.DateOfReceipt
		|		END,
		|		CASE
		|			WHEN NOT Schedule.Stage IS NULL THEN
		|				Schedule.Ending
		|			ELSE
		|				CASE
		|					WHEN OrderStructure.DateOfReceipt <> DATETIME(1,1,1) THEN
		|						DATEADD(BEGINOFPERIOD(OrderStructure.DateOfReceipt, DAY), DAY, 1)
		|					ELSE
		|						DATETIME(1,1,1)
		|			END
		|		END
		|
		|	HAVING
		|		SUM(OrderStructure.ToSupply - OrderStructure.Replaced) <> 0
		|			OR SUM(OrderStructure.Scheduled) <> 0
		|			OR SUM(OrderStructure.AllocatedFromAvailableInventory) <> 0
		|			OR SUM(OrderStructure.AllocatedFromAvailableInventoryWithAssignment) <> 0
		|			OR SUM(OrderStructure.AllocatedInFreeProductionLots) <> 0 
		|			OR SUM(OrderStructure.AllocatedInAssignedProductionLots) <> 0
		|
		|) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Warehouse,
		|	NestedQuery.Purpose,
		|	NestedQuery.ProductionOrder,
		|	NestedQuery.KeyProducts
		|	
		|HAVING
		|	SUM(NestedQuery.Required2
		|			- CASE
		|				WHEN &ExcludeProductionScheduleData
		|					THEN NestedQuery.Scheduled + NestedQuery.AllocatedInFreeProductionLots + NestedQuery.AllocatedInAssignedProductionLots
		|				ELSE 0
		|			 END
		|			- CASE
		|				WHEN NestedQuery.ReceiptOrder = UNDEFINED
		|					THEN NestedQuery.AllocatedFromAvailableInventory + NestedQuery.AllocatedFromAvailableInventoryWithAssignment
		|				ELSE 0
		|			 END) > 0
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse";
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT DISTINCT
		|	LeadingTable.Products AS Products,
		|	LeadingTable.Characteristic AS Characteristic,
		|	LeadingTable.Warehouse AS Warehouse,
		|	&CurrentDayStart AS BeginningOfThisDay,
		|	CalculationOfSecurityMethodOverridable.Ref AS SupplyMethod
		|INTO TableMainSupplyMethod
		|FROM
		|	OrderStructureSupplyOfOrders AS LeadingTable
		|		
		|		LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE
		|		
		|WHERE
		|	LeadingTable.ToSupply > 0
		|
		|INDEX BY
		|	Products, SupplyMethod, Warehouse";
	
	// The main method of supply and the planned delivery date
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfMainMethodOfProviding(
		"LeadingTable.Products",
		"LeadingTable.Characteristic",
		"LeadingTable.Warehouse",
		"TRUE");
	QueryText = StrReplace(QueryText, "CalculationOfSecurityMethodOverridable.Ref", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfSecurityMethodOverridable ON TRUE",
		Substitutions.Joins);
	
	Texts.Add(QueryText);
	
	QueryText = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	LeadingTable.Products AS Products,
		|	LeadingTable.Characteristic AS Characteristic,
		|	LeadingTable.Warehouse AS Warehouse,
		|	CalculationOfDeliveryDateOverridable.PlannedDeliveryDate AS PlannedDeliveryDate
		|INTO PlannedDeliveryDateIsTemporary
		|FROM
		|	TableMainSupplyMethod AS LeadingTable
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|WHERE
		|	CalculationOfDeliveryDateOverridable.PlannedDeliveryDate > DATETIME(1, 1, 1)
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|DROP TableMainSupplyMethod;
		|DROP YearsOfEnterpriseScheduleTemporary;
		|DROP YearsOfEnterpriseSchedule";
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
		"LeadingTable.SupplyMethod",
		"&CurrentDayStart",
		"LeadingTable.Products",
		"LeadingTable.Warehouse");
	
	QueryText = StrReplace(QueryText, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	QueryText = StrReplace(QueryText, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE",
		Substitutions.Joins);
	
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	&Fields_Selection,
		|	NestedQuery.ProductionOrder AS ProductionOrder,
		|	NestedQuery.Stage                AS Stage,
		|	NestedQuery.KeyLot          AS KeyLot,
		|	CASE
		|		WHEN MAX(NestedQuery.SupplyDate) > MAX(NestedQuery.PlannedDeliveryDate)
		|			THEN
		|				MAX(NestedQuery.SupplyDate)
		|			ELSE
		|				MAX(NestedQuery.PlannedDeliveryDate)
		|	END AS SupplyDate,
		|	CASE
		|		WHEN MAX(NestedQuery.AvailabilityDate) > MAX(DATEADD(BEGINOFPERIOD(NestedQuery.PlannedDeliveryDate, DAY), DAY, 1))
		|			THEN
		|				MAX(NestedQuery.AvailabilityDate)
		|			ELSE
		|				MAX(DATEADD(BEGINOFPERIOD(NestedQuery.PlannedDeliveryDate, DAY), DAY, 1))
		|	END AS AvailabilityDate
		|INTO TTProductionScheduleRestrictionsOnMaterials
		|FROM
		|	(SELECT
		|		OrderFulfillment.Products        AS Products,
		|		OrderFulfillment.Characteristic      AS Characteristic,
		|		OrderFulfillment.Warehouse               AS Warehouse,
		|		OrderFulfillment.ProductionOrder AS ProductionOrder,
		|		OrderFulfillment.Stage                AS Stage,
		|		OrderFulfillment.KeyLot          AS KeyLot,
		|		OrderFulfillment.SupplyDate     AS SupplyDate,
		|		OrderFulfillment.AvailabilityDate     AS AvailabilityDate,
		|		ISNULL(PlannedDeliveryDateIsTemporary.PlannedDeliveryDate, DATETIME(1,1,1)) AS PlannedDeliveryDate
		|	FROM
		|		OrderStructureSupplyOfOrders AS OrderFulfillment
		|	
		|			LEFT JOIN PlannedDeliveryDateIsTemporary AS PlannedDeliveryDateIsTemporary
		|			ON OrderFulfillment.Products   = PlannedDeliveryDateIsTemporary.Products
		|			 AND OrderFulfillment.Characteristic = PlannedDeliveryDateIsTemporary.Characteristic
		|			 AND OrderFulfillment.Warehouse          = PlannedDeliveryDateIsTemporary.Warehouse
		|			 AND OrderFulfillment.ToSupply > 0
		|	
		|) AS NestedQuery
		|	
		|GROUP BY
		|	&FieldsGroup,
		|	NestedQuery.ProductionOrder,
		|	NestedQuery.Stage,
		|	NestedQuery.KeyLot
		|
		|INDEX BY
		|	ProductionOrder,
		|	Stage,
		|	KeyLot
		|;
		|DROP PlannedDeliveryDateIsTemporary;
		|DROP OrderStructureSupplyOfOrders";
	
	// Substituting selection fields
	If ByProductCategory Then
		QueryText = StrReplace(QueryText, "&Fields_Selection", "
			|	NestedQuery.Products    AS Products,
			|	NestedQuery.Characteristic  AS Characteristic");
	Else
		QueryText = StrReplace(QueryText, "&Fields_Selection,", "");
	EndIf;
	
	// Substitution of grouping fields
	If ByProductCategory Then
		QueryText = StrReplace(QueryText, "&FieldsGroup", "
			|NestedQuery.Products,
			|NestedQuery.Characteristic");
	Else
		QueryText = StrReplace(QueryText, "&FieldsGroup,", "");
	EndIf;
	
	Texts.Add(QueryText);
	
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	Query = New Query(QueryText);
	
	If TypeOf(GettingCondition) = Type("String") Then // Temp table of the list of items of the nomenclature plan
		
		Query.Text = StrReplace(Query.Text, "&GettingCondition", StrReplace(GettingCondition, "&TextTableName", "OrderStructure")); 
		
	Else

		If TypeOf(GettingCondition) = Type("DocumentRef.ProductionOrder2_2") Then
		
			Query.Text = StrReplace(Query.Text, "&GettingCondition", "OrderStructure.ProductionOrder = &ProductionOrder");
			Query.SetParameter("ProductionOrder", GettingCondition);
			
		Else
			
			SelectionConstructor = New Array;
			
			For Each KeyValue In GettingCondition Do
				SelectionConstructor.Add(StrTemplate("FilterTable.%1 = &%1", KeyValue.Key));
				Query.SetParameter(KeyValue.Key, KeyValue.Value);
			EndDo;
		
			ConditionForReceivingQueryText = 
				"TRUE IN
				|	(SELECT TOP 1
				|		TRUE
				|	FROM
				|		InformationRegister.OrderStructure AS FilterTable
				|	WHERE
				|		&FilterText1
				|		AND FilterTable.Products        = OrderStructure.Products
				|		AND FilterTable.Characteristic      = OrderStructure.Characteristic
				|		AND FilterTable.Warehouse               = OrderStructure.Warehouse
				|		AND FilterTable.Purpose          = OrderStructure.Purpose
				|		AND FilterTable.ProductionOrder = OrderStructure.ProductionOrder
				|		AND FilterTable.KeyProducts    = OrderStructure.KeyProducts
				|		AND FilterTable.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption))";
			
			ConditionForReceivingQueryText =
				StrReplace(
					ConditionForReceivingQueryText,
					"&FilterText1",
					?(SelectionConstructor.Count() > 0, StrConcat(SelectionConstructor, " And "), "FALSE"));
			
			Query.Text = StrReplace(Query.Text, "&GettingCondition", ConditionForReceivingQueryText);
	
		EndIf;
		
	EndIf;
	
	CurrentDayStart = BegOfDay(CurrentSessionDate());
	
	Query.SetParameter("ScheduleStatus", ScheduleStatus);
	Query.SetParameter("CurrentDayStart", CurrentDayStart);
	Query.SetParameter("BeginningOfNextDay", CurrentDayStart + 86400);
	Query.SetParameter("ExcludeProductionScheduleData", ExcludeProductionScheduleData);
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

// According to the production schedule, it checks compliance with the condition: the date of providing materials is 
// earlier than the start date of the stages according to the schedule. Stages for which the condition is not met are marked as requiring recalculation.
//
// Parameters:
//  TempTablesManager - TempTablesManager - temp table manager, a temp table will be created in it.
//  FilterText1 - String - custom text for selecting lines in the order structure.
//
Procedure CheckTimingOfSupplyStagesOfDynamicStructure(TempTablesManager, FilterText1) Export
	
	SetPrivilegedMode(True);
	
	CreateTTConstraintsOfProductionScheduleBasedOnMaterialsDynamicStructure(
		TempTablesManager,
		FilterText1,
		False,
		False);
	
	Query = New Query(
		"SELECT DISTINCT
		|	Restrictions.ProductionOrder AS ProductionOrder,
		|	Restrictions.Stage                AS ProductionStage,
		|	Restrictions.KeyLot          AS KeyLot
		|FROM
		|	TTProductionScheduleRestrictionsOnMaterials AS Restrictions
		|
		|		INNER JOIN InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|		ON Restrictions.ProductionOrder = Schedule.ProductionOrder
		|			AND Restrictions.Stage             = Schedule.Stage
		|			AND Restrictions.KeyLot       = Schedule.KeyLot
		|			AND Schedule.ScheduleStatus = &WorkingSchedule
		|
		|WHERE
		|	Schedule.Begin < Restrictions.AvailabilityDate");
	
	Query.SetParameter("WorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.TempTablesManager = TempTablesManager;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(QueryResult.Unload());
	EndIf;
	
EndProcedure

// Updates the priority in the production stages after changing the priority in the production order.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Universal queue of operational tasks", there are also service columns:
//             * Object                 - DocumentRef          - link to the production order
//             * RecordID    - UUID -
//             * RecordDate             - Date                    -
//             * JobID   - UUID - Service_
//             * TaskDate_            - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure UpdatePriorityInProductionPhases(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.ProductionStage2_2 AS Table
		|WHERE
		|	Table.ReferenceOrder = &ProductionOrder
		|	AND Table.Posted");
	
	MetaOfRegister = Undefined;
	
	For Each Job In Jobs Do
	
		Try
			
			Query.SetParameter("ProductionOrder", Job.Object);
			Stages = Query.Execute().Unload().UnloadColumn(0);
			If Stages.Count() > 0 Then
				Documents.ProductionStage2_2.UpdateDocumentRegistry(Job.Object, Stages);
				StockAllocationRecords.WhenChangingPriority(Stages);
			EndIf;
			Stages = Undefined;
			
		Except
			
			If MetaOfRegister = Undefined Then
				
				MetaOfRegister = Metadata.InformationRegisters.UniversalQueueOfRealTimeJobs;
				
				EventName   = DeferredJobs.EventName();
				
				ErrorFields   = New Structure("Object");
				DataOfError = New Structure("Object");
				
				Jobs.Indexes.Add("Object");
				
			EndIf;
			
			ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName, EventLogLevel.Error, MetaOfRegister,, ExceptionText);
			
			DataOfError.Object = Job.Object;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, DataOfError, ExceptionText);
			
			FoundRows = Jobs.FindRows(DataOfError);
			For Each FoundRow In FoundRows Do
				IdsOfUnprocessedRecords.Insert(FoundRow.RecordID, ErrorText);
			EndDo;
			
		EndTry;
	
	EndDo;
	
EndProcedure

// Replaces the schedule of the PRODUCTION2_2 stages in the Query Text with the normative graph of the structure of the order, if necessary.
// 
// Parameters:
//  QueryText - String - The Query Text containing an access to the register of information of the production stage graph2_2
Procedure SubstitutionOfActualRegisterOfGraph(QueryText) Export
	
	If GetFunctionalOption("StandardOrderStructureScheduleIsUsed") Then
		QueryText = StrReplace(QueryText, "ScheduleOfProductionStages2_2", "TargetOrderStructureSchedule");
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Determines whether the production schedule is used.
// 
// Parameters:
//  ConstantsSet - ConstantsSet - the values of the constants.
// 
// Returns:
//   Boolean - True if the production schedule is used.
//
Function TheProductionScheduleIsUsed(ConstantsSet = Undefined) Export
	
	If ConstantsSet <> Undefined Then
		ManagementMethodology = ConstantsSet.ProductionManagementMethod;
	Else 
		ManagementMethodology = Constants.ProductionManagementMethod.Get();
	EndIf;
	
	Return ManagementMethodology <> Enums.ProductionManagementMethod.WithoutCalculationOfProductionSchedule;
	
EndFunction

Function DataForFillingNewProductionBatch(ReferenceOrder, AssignmentProducts) Export
	
	AttributesNames = New Structure;
	AttributesNames.Insert("Document", "Ref");
	AttributesNames.Insert("Organization");
	AttributesNames.Insert("LineOfBusiness");
	AttributesNames.Insert("VATActivityType", "OrderForActivity");
	
	SetPrivilegedMode(True);
	Result = Common.ObjectAttributesValues(ReferenceOrder, AttributesNames);
	SetPrivilegedMode(False);
	
	Result.Insert("Purpose", AssignmentProducts);
	
	If ValueIsFilled(AssignmentProducts) Then
		LineOfBusiness = ProductionManagementCached.DirectionOfActivityPurposeOfProduction(AssignmentProducts);
		Result.LineOfBusiness = LineOfBusiness;
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the date based on the passed mark
//
// Parameters:
//  Mark		 - Boolean	 - Mark
//  DateField_	 - Date		 - details to set the date in
//  EventDate	 - Date		 - set date
//  Erase	 - Boolean	 - indicates that the date must be set forcibly.
//
Procedure SetDateByMark(Mark, DateField_, EventDate = Undefined, Erase = False) Export
	
	If EventDate = Undefined Then
		EventDate = CurrentSessionDate();
	EndIf;
	
	If Not Mark And DateField_ <> '000101010000' Then
		DateField_  = '000101010000';
	ElsIf Mark And (DateField_ = '000101010000' Or Erase) Then
		DateField_ = EventDate;
	EndIf;
	
EndProcedure

// Returns the types of work centers used
// 
// Parameters:
//  Object - DocumentObject.ProductionStage2_2 - stage of production.
// 
// Returns:
//   - ValueTable
//
Function TypesOfWorkCentersUsed(Object) Export
	
	Result = New ValueTable;
	
	TypeDetails = New TypeDescription("CatalogRef.WorkCenterTypes");
	Result.Columns.Add("WorkCenterType", TypeDetails);
	
	TypeDetails = New TypeDescription("EnumRef.TimeMeasureUnits");
	Result.Columns.Add("UnitOfMeasure", TypeDetails);
	
	TypeDetails = Common.TypeDescriptionNumber(10, 1, AllowedSign.Nonnegative);
	Result.Columns.Add("OperationTime", TypeDetails);
	
	FilterParameters = New Structure("Use", True);
	
	For Each String In Object.WorkCenterTypes.FindRows(FilterParameters) Do
		FillPropertyValues(Result.Add(), String);
	EndDo;
	
	For Each String In Object.AlternateWorkCenterTypes.FindRows(FilterParameters) Do
		FillPropertyValues(Result.Add(), String);
	EndDo;
	
	Return Result;

EndFunction

Procedure UpdateScheduledAdmissionDates(Object, PlannedDateOfReceipt, PreviousValue) Export
	                                              
	// After manually changing the schedule, it is necessary to update the planned production dates
	If Object.Status <> Enums.StatusesOfProductionStages2_2.Initiated
		Or Not Object.StagePlacementInProductionSchedule Then
		Return;
	EndIf;
	
	If Object.ProductionInOneDay
		And Object.ProductionDate = PreviousValue Then
		
		ProductionManagement.SetDateByMark(
					True, 
					Object.ProductionDate,
					PlannedDateOfReceipt,
					True);
		
	EndIf;
	
	FilterStructure1 = New Structure();
	
	FilterStructure1.Insert("Manufactured", False);
	FilterStructure1.Insert("ProductionDate", PreviousValue);
	
	TablesNames = ProductionManagementClientServer.ProductTableNames();
	
	For Each TableName In TablesNames Do
		
		For Each String In Object[TableName].FindRows(FilterStructure1) Do
			
			ProductionManagement.SetDateByMark(
						True, 
						String.ProductionDate,
						PlannedDateOfReceipt,
						True);
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CompleteSelectionOfExpenditureItems(SelectionOfExpenditureItems) Export
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	OptionsArray.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostCenters);
	OptionsArray.Add(Enums.CostAllocationOptions.ToInventoryCost);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCostDirect);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostOfGoodsSold);
	AvailableCostSharingOptions = New FixedArray(OptionsArray);
	
	SelectionOfExpenditureItems.Insert("BusinessOperation", Enums.BusinessTransactions.GoodsConsumptionOnDemand);
	SelectionOfExpenditureItems.Insert("CostAllocationOption", AvailableCostSharingOptions);
	
EndProcedure

Function UseProductionOperationsAsReferencesForOutput(ComparedDate) Export
	
	If ComparedDate = Undefined Then
		Return False;
	EndIf;
		
	Date = ProductionManagementCached.StartDateOfAccountingForOutputByOperations();
	
	Return ValueIsFilled(Date) And ComparedDate >= Date;
	
EndFunction

// Used in the Readiness status report of the order of production in resource expressions
// 
// Parameters:
//  Stage - String - Stage
//  State - Number - State
// 
// Returns:
//  FormattedString - Formatting the stage
Function FormattedPresentationOfArrayOfStages(Val Stage, Val State = "") Export
	
	If TypeOf(Stage) = Type("Array") Then
		
		If Stage.Count() > 5 Then
			For IndexOf = -Stage.UBound() To -5 Do
				Stage.Delete(-IndexOf);
			EndDo;
		EndIf;
		
		If ValueIsFilled(Stage) Then
			Return New FormattedString(Stage);
		Else
			Return "";
		EndIf;
	EndIf;
	
	StageName = Stage + Chars.LF;
	
	If State = "Initiated" Then
		Return New FormattedString(StageName,,WebColors.Blue);
	ElsIf State = "Overdue" Then
		Return New FormattedString(StageName,,WebColors.Red)
	Else
		Return New FormattedString(StageName);
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ProductionOrder

// Parameters:
//  CreateCommandsBasedOn - ValueTable - 
// 
// Returns:
//  ValueTableRow
//
Function AddCreateSecuringOrderCommand(CreateCommandsBasedOn) Export
	
		ObjectManager = Metadata.Documents.ProductionOrder2_2;
		DocumentName = "ProductionOrder2_2";
	
	If AccessRight("Insert", ObjectManager) Then
		
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSecuringOrder";
		CreateBasedOnCommand.Manager =  ObjectManager.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(ObjectManager);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction";
		CreationParameters = ProvisionInDocumentsServer.ParametersForCreatingSecuringOrder(
			CreateBasedOnCommand.AdditionalParameters);
		CreationParameters.NameOfDocumentManager = DocumentName;
		CreationParameters.FormName = "Document." + DocumentName + ".ObjectForm";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function OrderSchedulePlanningQueue(References = Undefined)
	
	QueryText = 
		"SELECT
		|	QueueOfOrders.Ref                AS Ref,
		|	QueueOfOrders.DynamicStructure AS DynamicStructure
		|FROM
		|	Document.ProductionOrder2_2 AS QueueOfOrders
		|WHERE
		|	&RefsSelectionText
		|	AND QueueOfOrders.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|	AND QueueOfOrders.Posted
		|
		|ORDER BY
		|	QueueOfOrders.Priority.AddlOrderingAttribute,
		|	QueueOfOrders.Department.AddlOrderingAttribute,
		|	QueueOfOrders.Queue";
	
	If ValueIsFilled(References) Then
		QueryText = StrReplace(QueryText, "&RefsSelectionText", "QueueOfOrders.Ref IN (&References)");
	Else
		QueryText = StrReplace(QueryText, "&RefsSelectionText", "TRUE");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	
	Return Query.Execute().Select();
	
EndFunction

#EndRegion

#Region Stage

#Region ManufacturedProducts

Procedure FillInServiceDetailsOfOutputProductsOfProductionStage(TabularSection, FillInLines = Undefined) Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		TabularSection,
		StructureOfActions,
		FillInLines);
	
	ProductionServer.FillInShopPantryAttributeInTable(TabularSection, "Recipient",, FillInLines);
	
EndProcedure

#EndRegion

#Region Standards

Function GetStandards(Standards, DataArray, TheStructureOfTheSearch, ThereArePackages = False) Export
	
	Result = ProductionServer.CreateArray(DataArray.Count(), 0);
	
	If ValueIsFilled(Standards) Then
		
		If ThereArePackages Then
			
			RowDataWithPackages = New Array;
			MatchingStringsWithPackages = New Map;
			IndexOf = 0;
			For X = 0 To DataArray.UBound() Do
				RowData = DataArray[X];
				
				If Not ValueIsFilled(RowData.Products)
					Or RowData.ItemVariantsAreUsed And Not ValueIsFilled(RowData.Characteristic) Then
					Continue;
				EndIf;
				
				FillPropertyValues(TheStructureOfTheSearch, RowData);
				StringsList = Standards.FindRows(TheStructureOfTheSearch);
				If StringsList.Count() <> 0 Then
					
					For Each String In StringsList Do
						Result[X] = Result[X] + String.NumberOfPackages
							* String.PackageData.Numerator / String.PackageData.Denominator;
					EndDo;

					If ValueIsFilled(RowData.Package) Then
						RowDataWithPackages.Add(RowData);
						MatchingStringsWithPackages.Insert(IndexOf, X);
						IndexOf = IndexOf + 1;
					EndIf;
					
				EndIf;
				
			EndDo;
			
			If RowDataWithPackages.Count() <> 0 Then
				PackingFactors = Catalogs.PackagesAndUnitsOfMeasure.PackingFactors(RowDataWithPackages);
				For Cnt = 0 To RowDataWithPackages.UBound() Do
					X = MatchingStringsWithPackages.Get(Cnt);
					CurrentData = DataArray[X];
					ZoomRatio = PackingFactors.Get(CurrentData.Products).Get(CurrentData.Package);
					Result[X] = Result[X] / ZoomRatio;
				EndDo;
			EndIf;
			
		Else
			
			For X = 0 To DataArray.UBound() Do
				RowData = DataArray[X];
				
				ValueNotFilledIn = False;
				For Each KeyAndValue In TheStructureOfTheSearch Do
					If ValueIsFilled(KeyAndValue.Key) Then
						Continue;
					EndIf;
					ValueNotFilledIn = True;
					Break;
				EndDo;
				If ValueNotFilledIn Then
					Continue;
				EndIf;
				
				FillPropertyValues(TheStructureOfTheSearch, RowData);
				StringsList = Standards.FindRows(TheStructureOfTheSearch);
				If StringsList.Count() <> 0 Then
					Result[X] = StringsList[0].Count;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region LaborCosts

// Information about the contractor's place of work.
// 
// Parameters:
//  Performer - DefinedType.WorkAssignee - Performer
// 
// Returns:
//  Structure - Information About The Contractor's Place Of Work:
// * Department - CatalogRef.BusinessStructure
// * Organization - CatalogRef.Companies
Function InformationAboutContractorSPlaceOfWork(Performer) Export
	
	InformationAboutPlaceOfWork = New Structure("Department,Organization",
		Catalogs.BusinessStructure.EmptyRef(),
		Catalogs.Companies.EmptyRef());
	
	PerformerType = TypeOf(Performer);
	
	If PerformerType = Type("CatalogRef.Persons") Then
		// in the Cur configuration, obtaining information about the place of work is not provided


	ElsIf PerformerType = Type("CatalogRef.Teams") Then
		Query = New Query(
		"SELECT
		|	Teams.Department AS Department,
		|	Teams.Organization AS Organization
		|FROM
		|	Catalog.Teams AS Teams
		|WHERE
		|	Teams.Ref = &Performer");
		Query.SetParameter("Performer", Performer);
		Selection = Query.Execute().Select();
		Selection.Next();
		FillPropertyValues(InformationAboutPlaceOfWork, Selection);		
	EndIf;
	
	Return InformationAboutPlaceOfWork;
	
EndFunction

#EndRegion

#Region Other

Procedure UpdateAttributeYouNeedToFillInStageConsumerField(Form, OrderList) Export
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionOrder2_2 AS Orders
	|WHERE
	|	Orders.Ref IN (&OrderList)
	|	AND Orders.DisabledAssignmentByProductionStageForIntermediateProducts
	|");
	Query.SetParameter("OrderList", OrderList);
	Form.FillInTheStageConsumerField = Not Query.Execute().IsEmpty();
	
EndProcedure

// Describes the service data that is used when editing a stage
//
// Parameters:
//  Mode	 - String	 - stage editing mode (options: Object, Processing).
// 
// Returns:
//  Structure - stage editing parameters.
//
Function StageEditingParameters(Mode) Export

	Result = New Structure();
	
	Result.Insert("Mode", Mode);
	Result.Insert("ThisIsOrderToProcessor", False);
	
	Result.Insert("PropsNameObject", "Object");
	Result.Insert("PropsNameLink", "Ref");
	
	Result.Insert("PropsNameParametersForSpecifyingSeries", "SeriesSpecificationParameters");
	
	Return Result;

EndFunction

Procedure FillInWHReleaseDirection(RowsCollection) Export
	
	For Each RowData In RowsCollection Do
		
		If RowData.ToExpenseAs Then
			RowData.DirectionOfProductionIssue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
		ElsIf RowData.ItemsType = Enums.ItemsTypes.Work_5 Then
			RowData.DirectionOfProductionIssue = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;
		Else
			RowData.DirectionOfProductionIssue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
		EndIf;
		
		If Not ValueIsFilled(RowData.ExpenseItem) Then
			RowData.ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CompleteStageByStatus(Object, FillingData = Undefined, ChangedBankingDetails = "")
	StatusIsGenerated = PredefinedValue("Enum.StatusesOfProductionStages2_2.BeingGenerated");
	GeneratedStatus = PredefinedValue("Enum.StatusesOfProductionStages2_2.Generated1");
	StatusPending = PredefinedValue("Enum.StatusesOfProductionStages2_2.ForCompletion");
	StatusStarted       = PredefinedValue("Enum.StatusesOfProductionStages2_2.Initiated");
	StatusCompleted_1    = PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed");
	
	AllQuantityIsFulfilled = False;
	
	If Object.Status = StatusCompleted_1 Then
		
		If Object.ProductionByThirdParty
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials Then
			
			AllQuantityIsFulfilled = True;
			
		Else
			
			QueryText = 
				"SELECT
				|	ProductionLots.MainProductProducts    AS Products,
				|	ProductionLots.MainProductCharacteristic  AS Characteristic,
				|	ISNULL(&QueryTextPackagingFactorPlan, 1) AS CoefficientPlan,
				|	ISNULL(&QueryTextPackagingFactorFact, 1) AS CoefficientFact
				|FROM
				|	Catalog.ProductionLots AS ProductionLots
				|WHERE
				|	ProductionLots.Ref = &ProductionLot";
			
			QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactorPlan",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"CAST(&PackagePlan AS Catalog.PackagesAndUnitsOfMeasure)",
					"ProductionLots.MainProductProducts"));
			
			QueryText = StrReplace(QueryText,
				"&QueryTextPackagingFactorFact",
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
					"CAST(&PackageActualData AS Catalog.PackagesAndUnitsOfMeasure)",
					"ProductionLots.MainProductProducts"));
			
			Query = New Query(QueryText);
			Query.SetParameter("ProductionLot", Object.ProductionLot);
			Query.SetParameter("PackagePlan", Object.PackagePlan);
			Query.SetParameter("PackageActualData", Object.PackageActualData);
			
			FinishedProductOfLotReference = Query.Execute().Select();
			FinishedProductOfLotReference = ?(FinishedProductOfLotReference.Next(), FinishedProductOfLotReference, Undefined);
			
			// Filling in the fact on the issue
			If Object.NumberOfPackagesReal = 0
				And Object.ManufacturedProducts.Count() <> 0
				And FinishedProductOfLotReference <> Undefined Then
				
				NumberOfPackages = 0;
				Count = 0;
				Package = Object.PackageActualData;
				
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("Products", FinishedProductOfLotReference.Products);
				TheStructureOfTheSearch.Insert("Characteristic", FinishedProductOfLotReference.Characteristic);
				TheStructureOfTheSearch.Insert("Manufactured", True);
				TheStructureOfTheSearch.Insert("Canceled", False);
				
				For Each String In Object.ManufacturedProducts.FindRows(TheStructureOfTheSearch) Do
					If Package <> Undefined Then
						If Package = String.Package Then
							NumberOfPackages = NumberOfPackages + String.NumberOfPackages;
						Else
							Package = Undefined;
						EndIf;
					EndIf;
					Count = Count + String.Count;
				EndDo;
				
				If Package = Undefined Then
					Object.NumberOfPackagesReal = Count / FinishedProductOfLotReference.CoefficientFact;
				Else
					Object.NumberOfPackagesReal = NumberOfPackages;
				EndIf;
				
				If Object.NumberOfPackagesReal <> 0 Then
					ChangedBankingDetails = ChangedBankingDetails + ",NumberOfPackagesReal";
				EndIf;
				
			EndIf;
			
			// Installation fact = plan
			If Object.NumberOfPackagesReal = 0
					And Object.NumberOfPackagesCanceled = 0 Then
				Object.NumberOfPackagesReal = Object.NumberOfPackagesPlan;
				Object.PackageActualData = Object.PackagePlan;
				ChangedBankingDetails = ChangedBankingDetails + ",NumberOfPackagesReal,PackageActualData";
			EndIf;
			
			// Calculation of all quantities completed
			If Object.NumberOfPackagesCanceled = 0
				And FinishedProductOfLotReference <> Undefined Then
				If Object.PackageActualData = Object.PackagePlan Then
					AllQuantityIsFulfilled = Object.NumberOfPackagesReal >= Object.NumberOfPackagesPlan;
				Else
					AllQuantityIsFulfilled = (Object.NumberOfPackagesReal * FinishedProductOfLotReference.CoefficientFact)
						>= (Object.NumberOfPackagesPlan * FinishedProductOfLotReference.CoefficientPlan);
				EndIf;
			EndIf;
			
		EndIf;
			
	ElsIf Object.Status <> StatusStarted Then
		
		Object.NumberOfPackagesReal = 0;
		ChangedBankingDetails = ChangedBankingDetails + ",NumberOfPackagesReal";
		
	EndIf;
	
	PlannedDateOfReceipt = '00010101';
	
	If FillingData <> Undefined And FillingData.Property("PlannedDateOfReceipt") And ValueIsFilled(FillingData.PlannedDateOfReceipt) Then
		PlannedDateOfReceipt = FillingData.PlannedDateOfReceipt;
	EndIf;
	
	ProductTableNames = ProductionManagementClientServer.ProductTableNames();
	
	// Output products and labor costs
	If (Object.Status = StatusIsGenerated
			Or Object.Status = GeneratedStatus
			Or Object.Status = StatusPending
			Or Object.Status = StatusCompleted_1)
		And Not Object.ProductionByThirdParty Then
		
		Mark = (Object.Status = StatusCompleted_1);
		
		SetMarkProduced = True;
		
		If Object.Status = StatusCompleted_1 Then
			
			If AllQuantityIsFulfilled Then
				
				FilterStructure1 = New Structure("Manufactured", True);
				For Each TableName In ProductTableNames Do
				
					If Object[TableName].FindRows(FilterStructure1).UBound() <> -1 Then
						SetMarkProduced = False;
						Break;
					EndIf;
					
				EndDo;
				
			Else
				SetMarkProduced = False;
			EndIf;
			
		EndIf;
		
		If SetMarkProduced Then
			
			ProductionDate = Undefined;

			If Mark Then
				ProductionDate = CurrentSessionDate();
			EndIf;    
			
			If Mark 
				And Object.ProductionInOneDay Then
				
				ProductionManagement.SetDateByMark(
							True,
							Object.ProductionDate, ProductionDate, True);
				
			EndIf;
						
			For Each TableName In ProductTableNames Do
				
				For Each String In Object[TableName] Do
					
					If (TableName = "ManufacturedProducts"
							Or TableName = "SideAndIntermediateRelease")
							And String.Canceled Then
						Continue;
					EndIf;
					
					String.Manufactured = Mark;
					
					If Mark Then
						ProductionManagement.SetDateByMark(
									True, 
									String.ProductionDate, ProductionDate, True);
					EndIf;
					
				EndDo;
				
			EndDo;
			
			Documents.ProductionStage2_2.FillInPricesByPriceKind(Object);
			
		EndIf;
		
		// LaborCosts
		SetMarkCompleted = True;
		
		If Object.Status = StatusCompleted_1 Then
			
			If AllQuantityIsFulfilled Then
				FilterStructure1 = New Structure("Completed2", True);
				If Object.LaborCosts.FindRows(FilterStructure1).UBound() <> -1 Then
					SetMarkCompleted = False;
				EndIf;
			Else
				SetMarkCompleted = False;
			EndIf;
			
		EndIf;
		
		If SetMarkCompleted
			And Documents.ProductionStage2_2.MarkOfPerformedLaborCostsIsUsed(Object) Then
			
			For Each String In Object.LaborCosts Do
				
				If String.Canceled Then
					Continue;
				EndIf;
				
				String.Completed2 = Mark;
				
				ProductionManagement.SetDateByMark(
							Mark, 
							String.ExecutionDate,, True);
							
				If Not ValueIsFilled(String.Performer) Then 
					String.Performer = Object.Performer;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	ElsIf Object.Status = StatusStarted Then
		
		If Object.ProductionInOneDay Then
			
			ProductionManagement.SetDateByMark(
						True, 
						Object.ProductionDate, PlannedDateOfReceipt);
			
		EndIf;
		
		FilterStructure1 = New Structure("Manufactured", False);
		
		For Each TableName In ProductTableNames Do
			
			For Each String In Object[TableName].FindRows(FilterStructure1) Do
				
				ProductionManagement.SetDateByMark(
							True, 
							String.ProductionDate, PlannedDateOfReceipt);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	// Provision, consumption and saving of materials
	If Not Object.ProductionByThirdParty Then
		
		If (Object.Status = StatusIsGenerated
			Or Object.Status = GeneratedStatus
			Or Object.Status = StatusPending) Then
		
			Documents.ProductionStage2_2.CancelShipAction(Object);
			
			If Object.Status = StatusIsGenerated Then
				Documents.ProductionStage2_2.CancelReserveAction(Object);
			EndIf;
			
			Object.MaterialsAndWorksConsumption.Clear();
			
			Object.UnusedMaterials.Clear();
			Object.SavingMaterialsBatch.Clear();
			
			ChangedBankingDetails = ChangedBankingDetails + ",MaterialsAndWorksConsumption,UnusedMaterials";
			
		ElsIf Object.Status = StatusCompleted_1 Then
			
			If Object.SupplyWithMaterialsAndWorks.Count() > 0 Then
				
				LinesForShipment = New Array;
				For Each String In Object.SupplyWithMaterialsAndWorks Do
					If String.SupplyOption <> Enums.SupplyOptions.Ship
						And Not String.Canceled Then
						LinesForShipment.Add(String);
					EndIf;
				EndDo;
				
				YouNeedToFillInForm = (LinesForShipment.Count() <> 0);
				
				If (YouNeedToFillInForm) Then
					
					ShipInInstallments = (LinesForShipment.Count() <> Object.SupplyWithMaterialsAndWorks.Count());
					If Object.NotShipInInstallments Then
						If ShipInInstallments Then
							Object.NotShipInInstallments = False;
							Object.DateOfShipment = '00010101';
						Else
							Object.DateOfShipment = BegOfDay(CurrentSessionDate());
						EndIf;
					EndIf;
					
					Documents.ProductionStage2_2.SetShipAction(Object);
					
				EndIf;
				
				RequiredToFillInExpense = Object.MaterialsAndWorksConsumption.Count() = 0
					And Object.UnusedMaterials.Count() = 0
					And AllQuantityIsFulfilled;
				
				If RequiredToFillInExpense Then
					
					If Object.ConsumptionInOneDay Then
						Object.DateOfMaterialWorkConsumption = BegOfDay(CurrentSessionDate());
					EndIf;
					
					Documents.ProductionStage2_2.FillInConsumptionOfMaterialsAndWorksAccordingToProvisionData(Object);
					ChangedBankingDetails = ChangedBankingDetails + ",MaterialsAndWorksConsumption";
					
				EndIf;
				
				ChangedBankingDetails = ChangedBankingDetails + ",DateOfShipment,NotShipInInstallments,DateOfMaterialWorkConsumption,ConsumptionInOneDay";
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// The indication of the series depends on the status
	SeriesSpecificationParameters = Documents.ProductionStage2_2.SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.ManufacturedProducts);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SideAndIntermediateRelease);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.MaterialsAndWorksConsumption);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters.UnusedMaterials);
	
EndProcedure

Function BatchFormationOfStagesIsPerformed(Object) Export
	
	Return Object.AdditionalProperties.Property(KeyBatchModeForGeneratingStages());
	
EndFunction

Function KeyBatchModeForGeneratingStages() Export
	
	Return "BatchModeOfFormationOfStages";
	
EndFunction

Procedure SetDateOfCompletionOfLaborCosts(CurrentData, EventDateCompletion) Export
	
	ProductionManagement.SetDateByMark(CurrentData.Completed2, CurrentData.ExecutionDate, EventDateCompletion);
	
EndProcedure

#EndRegion

#Region ConditionalAppearance
 
// Adds the conditional design of output items of the production stage to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  ItemsNames   - Structure - names of the form elements.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfOutputProductsOfProductionStage(Form, ObjectName, TSName, ItemsNames, DataPaths = Undefined) Export

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	// StandardAppearance
	#Region StandardAppearance
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = ItemsNames.ProductsUnitOfMeasure;
	ConditionalDesignParameters.PathToPackagingUnitField = ObjectName + "." + TSName + ".Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		Form,
		ItemsNames.Characteristic,
		ObjectName + "." + TSName + ".ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		Form,
		False,
		ItemsNames.Series,
		ObjectName + "." + TSName + ".BatchesIndicationStatus",
		ObjectName + "." + TSName + ".ItemsType");
		
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		Form,
		False,
		ItemsNames.BatchesIndicationStatus,
		ObjectName + "." + TSName + ".BatchesIndicationStatus");
		
	ProductsServer.SetConditionalAppearanceOfProductAssignment(
		Form,
		ItemsNames.Purpose,
		ObjectName + "." + TSName + ".ItemsType",
		False);
		
	#EndRegion
	
	// The production date is required to be filled in with the status started, completed
	#Region ProductionDate
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Initiated);
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Completed);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ProductionDate);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = StatusesList;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
	#Region Purpose
	
	// Purpose in the toll-free scheme, in the manufacture of the disassembled product.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.Purpose);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	// Tolling scheme
	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	GivingOperations = New ValueList;
	GivingOperations.Add(Enums.BusinessTransactions.TollManufacturing2_5);
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = GivingOperations;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	// Production and further disassembly of the product
	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", Upper(TSName) <> Upper("SideAndIntermediateRelease"));
	
	// the purpose is not indicated when writing off expenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.Purpose);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
													|ru = '<не используется при списании на расходы>';
													|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
													|it = '<non viene usato durante storno sulle spese>';
													|pl = '<nie używane podczas rozchodu na wydatki>';
													|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	
	// Representation of the output direction field
	#Region DirectionOfProductionIssue
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.DirectionOfProductionIssue);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Điều chuyển hàng hóa';
													|ru = 'На склад';
													|en = 'To warehouse'; fa = 'To warehouse';
													|it = 'Al magazzino';
													|pl = 'Na magazyn';
													|tr = 'Ambara'"));
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.DirectionOfProductionIssue);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToBusinessUnit;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Sang bộ phận';
													|ru = 'В подразделение';
													|en = 'To business unit'; fa = 'To business unit';
													|it = 'Al reparto';
													|pl = 'Do działu';
													|tr = 'Departmana'"));

	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.DirectionOfProductionIssue);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списать на расходы';
													|en = 'Expense as'; fa = 'هزینه به عنوان';
													|it = 'Stornare sulle spese';
													|pl = 'Spisać w koszty';
													|tr = 'Gider olarak kaydet'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.DirectionOfProductionIssue);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.BusinessOperation");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TollManufacturing2_5;
	
	Item.Appearance.SetParameterValue("Visible", Upper(TSName) <> Upper("ManufacturedProducts"));
	
	#EndRegion
	
	// Article and analytics only if we write off for expenses, otherwise the recipient is indicated.
	#Region DimensionOfExpenses
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ExpenseItem);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.DimensionOfExpenses);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.AssetsLiabilitiesDimension);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.TransactionRecordingPresentation);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	// Representation of fields when canceling rows
	#Region CancelLines
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.Manufactured);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.Recipient);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.NumberOfPackages);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items[TSName],
		ItemsNames.Canceled,
		ItemsNames.CancellationReason);
	
	#EndRegion
	
	// Process by specification
	#Region ProcessByBOM
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.BillOfMaterials);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".BillOfMaterials");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có bảng kê chi tiết các nguồn lực sản xuất>';
													|ru = '<без спецификации>';
													|en = '<without bill of materials>'; fa = '<without bill of materials>';
													|it = '<senza specifica>';
													|pl = '<bez specyfikacji>';
													|tr = '<ürün reçetesiz>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ValueOfPredefinedText);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.BillOfMaterials);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.BillOfMaterials);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(ItemsNames.ProcessByBOM);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".DirectionOfProductionIssue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.BusinessTransactions.ProductsReleaseToWarehouse;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	// Receiving department
	SetConditionalAppearanceRecipient(Form, ObjectName, TSName, , DataPaths);
	
	// Quality control
	SetConditionalAppearanceOfQualityControlDetails(Form, ObjectName, TSName, , DataPaths);
	
EndProcedure

// Adds a conditional design for the purpose of output items of the production stage to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfDestinationOfOutputProductsOfProductionStage(Form, DataPaths = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	// The purpose is mandatory: in the tolling scheme, during the production of the disassembled product.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["ManufacturedProductsPurpose"]["Name"]);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	
	// Production and further disassembly of the product
	SelectionGroupAnd = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ManufacturedProducts.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

// Adds a conditional design of the purpose of the by-products of the production stage to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfAppointmentOfByProductsOfProductionStage(Form, DataPaths = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	// The purpose is mandatory: in the tolling scheme, during the production of the disassembled product.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items["SideAndIntermediateReleasePurpose"]["Name"]);
	
	// Production and further disassembly of the product
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.ProcessByBOM");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SideAndIntermediateRelease.Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

// Returns the structure of keys for specifying the names of the fields of the table of consumable materialsreferences
// 
// Returns:
//  Structure - structure with keys:
//   * ProductsUnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
//   * Characteristic - CatalogRef.ItemsCharacteristics -
//   * Series - CatalogRef.ItemsBatches -
//   * ProductCostElement - CatalogRef.ProductCostElements -
//
Function NamesOfElementsConsumptionOfMaterialsAndWorksOfProductionStage() Export
	
	ItemsNames = New Structure;
	ItemsNames.Insert("ProductsUnitOfMeasure");
	ItemsNames.Insert("Characteristic");
	ItemsNames.Insert("Series");
	ItemsNames.Insert("ProductCostElement");
	
	Return ItemsNames;
	
EndFunction

// Adds a conditional design for saving materials for the production stage to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceForMaterialsOfProductionStage(Form, ObjectName, DataPaths = Undefined) Export

	ConditionalAppearance = Form.ConditionalAppearance;
	
	// StandardAppearance
	#Region StandardAppearance
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UnusedMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = ObjectName + ".UnusedMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		Form,
		"UnusedMaterialsCharacteristic",
		ObjectName + ".UnusedMaterials.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		Form,
		False,
		"UnusedMaterialsSeries",
		ObjectName + ".UnusedMaterials.BatchesIndicationStatus",
		ObjectName + ".UnusedMaterials.ItemsType");
		
	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(
		Form,
		False,
		"UnusedMaterialsBatchesIndicationStatus",
		ObjectName + ".UnusedMaterials.BatchesIndicationStatus");
	
	#EndRegion
	
	// Text for the Action field
	#Region Actions
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsActions");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".UnusedMaterials.Actions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReturnFromProduction;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chuyển đến kho';
													|ru = 'Передать на склад';
													|en = 'Transfer to warehouse'; fa = 'انتقال به انبار';
													|it = 'Trasferire al magazzino';
													|pl = 'Przekaż do magazynu';
													|tr = 'Ambara transfer et'"));
	
	//
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsActions");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".UnusedMaterials.Actions");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списать на расходы';
													|en = 'Expense as'; fa = 'هزینه به عنوان';
													|it = 'Stornare sulle spese';
													|pl = 'Spisać w koszty';
													|tr = 'Gider olarak kaydet'"));
	#EndRegion
	
	// Article and analytics only if we write off for expenses, otherwise the recipient is indicated.
	#Region DimensionOfExpenses
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsExpenseItem");

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsDimensionOfExpenses");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsAssetsLiabilitiesDimension");
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsTransactionRecordingPresentation");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".UnusedMaterials.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);
	#EndRegion
	
	// The purpose is not specified for the container
	#Region Purpose_MultiTurnPackaging
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsAssign");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".UnusedMaterials.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsLabelPurpose");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".UnusedMaterials.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.ReusablePackage;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để đóng gói>';
													|ru = '<не используется для тары>';
													|en = '<not used for package>'; fa = '<not used for package>';
													|it = '<non viene usato per imballaggio>';
													|pl = '<nie używane do opakowania>';
													|tr = '<ambalaj için kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	// the purpose is not indicated when writing off expenses
	#Region Assignment_ChargeToExpenses
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("UnusedMaterialsPurpose");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + ".UnusedMaterials.ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không được sử dụng để khấu trừ chi phí>';
													|ru = '<не используется при списании на расходы>';
													|en = '<not used while writing off as expenses>'; fa = '<not used while writing off as expenses>';
													|it = '<non viene usato durante storno sulle spese>';
													|pl = '<nie używane podczas rozchodu na wydatki>';
													|tr = '<giderlere yazılırken kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
	
	// Receiving department
	SetConditionalAppearanceRecipient(Form, ObjectName, "UnusedMaterials",, DataPaths);
	
EndProcedure

// Adds to the form the conditional design of the material consumption and work of the production stage.
//
// Parameters:
//  Form          - ClientApplicationForm - shape.
//  ObjectName     - String - object name.
//  TSName          - String - name of the table part.
//  ItemsNames - See NamesOfElementsConsumptionOfMaterialsAndWorksOfProductionStage.
//  DataPaths    - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfConsumptionOfMaterialsAndWorksOfProductionStage(Form, ObjectName, TSName, ItemsNames, DataPaths = Undefined) Export
	
	// StandardAppearance
	#Region StandardAppearance
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = ItemsNames.ProductsUnitOfMeasure;
	ConditionalDesignParameters.PathToPackagingUnitField = ObjectName + "." + TSName + ".Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(Form, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		Form,
		ItemsNames.Characteristic,
		ObjectName + "." + TSName + ".ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		Form,
		"SeriesAlwaysWHGoods",
		ItemsNames.Series,
		ObjectName + "." + TSName + ".BatchesIndicationStatus",
		ObjectName + "." + TSName + ".ItemsType");
	
	#EndRegion
	
	TagName = ItemsNames.ProductCostElement;
	
	ProductionFormManagement.SetConditionalAppearanceOfCalculationArticle(Form, ObjectName, TSName, TagName, DataPaths);
	
EndProcedure

// Adds conditional registration of labor costs to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  ElementPrefix - String - prefix of elements.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfLaborCosts(Form, ObjectName, TSName, ElementPrefix = "", DataPaths = Undefined) Export

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Performer"]["Name"]);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Completed2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Completed2"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Count"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Canceled");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	OrdersServer.SetAppearanceOfCanceledLine(
		ConditionalAppearance,
		Items[ElementPrefix + TSName],
		Items[ElementPrefix + TSName + "Canceled"]["Name"],
		Items[ElementPrefix + TSName + "CancellationReason"]["Name"]);
	
	//
	
	TagName = ElementPrefix + TSName + "ProductCostElement";
	
	ProductionFormManagement.SetConditionalAppearanceOfCalculationArticle(
		Form, ObjectName, TSName, TagName, DataPaths, True);
	
EndProcedure

Procedure SetConditionalAppearanceRecipient(Form, ObjectName, TSName, ElementPrefix = "", DataPaths = Undefined)

	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	// The recipient is the same as the issuing department
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Recipient"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Recipient");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", New DataCompositionField(ObjectName + "." + TSName + ".Department"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// The recipient is not required to fill in
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Recipient"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	If Not TSName = "UnusedMaterials" Then
		
		// The products remain for further processing
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items[TSName + "Recipient"]["Name"]);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue  = New DataCompositionField(ObjectName + "." + TSName + ".ItemsType");
		ItemFilter.ComparisonType   = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = Enums.ItemsTypes.Work_5;
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue  = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "LeaveProductsAtSubcontractor");
		Filter.ComparisonType   = DataCompositionComparisonType.Equal;
		Filter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text",                 NStr("vi = '<không cần>';
																		|ru = '<не требуется>';
																		|en = '<not required>'; fa = '<الزامی نیست>';
																		|it = '<non richiesto>';
																		|pl = '<nie jest wymagane>';
																		|tr = '<gerekli değil>'"));
		Item.Appearance.SetParameterValue("TextColor",            StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("MarkIncomplete", False);
		Item.Appearance.SetParameterValue("ReadOnly",        True);
		
	EndIf;
	
EndProcedure

// Adds conditional design for the Price and Amount fields to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  ElementPrefix - String - prefix of elements.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure EstablishConditionalAppearanceOfFixedCostOfProductionStage(Form, ObjectName, TSName, ElementPrefix = "", DataPaths = Undefined) Export
	
	// Description:
	// - the price and amount for by-products are mandatory in the status Started and Completed if the products are released
	// - the price and amount for by-products are available if the products are released or the type of prices is not filled in.
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	StatusesList = New ValueList;
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Initiated);
	StatusesList.Add(Enums.StatusesOfProductionStages2_2.Completed);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Price"]["Name"]);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Sum"]["Name"]);
	
	SelectionGroupOr = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = StatusesList;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Price"]["Name"]);
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "Sum"]["Name"]);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "PriceKind");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "ProductionByThirdParty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Manufactured");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

// Adds a conditional design for the this Consumer field to the form.
//
// Parameters:
//  Form            - ClientApplicationForm - shape.
//  ObjectName       - String - object name.
//  TSName            - String - name of the table part.
//  ElementPrefix - String - prefix of elements.
//  DataPaths      - Structure, Undefined - the path to the data.
//
Procedure SetConditionalAppearanceOfStageConsumerOfSemiFinishedProductField(Form, ObjectName, TSName, ElementPrefix = "", DataPaths = Undefined) Export
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "StageConsumer"]["Name"]);
	
	SelectionGroupOr = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupOr.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".Purpose");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupOr.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(ObjectName + "." + TSName + ".ToExpenseAs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "StageConsumer"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillInTheStageConsumerField");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", True);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items[ElementPrefix + TSName + "StageConsumer"]["Name"]);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FillInTheStageConsumerField");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
EndProcedure

Procedure SetConditionalAppearanceOfQualityControlDetails(Form, ObjectName, TSName, ElementPrefix = "", DataPaths = Undefined)
	
	ConditionalAppearance = Form.ConditionalAppearance;
	Items = Form.Items;
	
	Fields = QualityControl.Fields(
		Items[TSName + "ToControlQuality"],
		Items[TSName + "QualityConfirmationDate"]);
	
	FlagDisabled = New Array();
	DateIsOptional = New Array();
	
	Statuses = Enums.StatusesOfProductionStages2_2;
	ItemsTypes = Enums.ItemsTypes;
	
	QualityControl.AddFilter(FlagDisabled, ObjectName + "." + TSName + ".Canceled", True);
	QualityControl.AddFilter(FlagDisabled, ObjectName + "." + TSName + ".ToExpenseAs", True);
	QualityControl.AddFilter(FlagDisabled, ObjectName + "." + TSName + ".ItemsType", ItemsTypes.Work_5);
	
	QualityControl.AddFilter(
		FlagDisabled,
		ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "LeaveProductsAtSubcontractor"),
		True);
	
	QualityControl.AddFilter(
		FlagDisabled,
		ProductionFormManagement.PathDataLayoutField(ObjectName, DataPaths, "ProductionByThirdParty2_5"),
		False);
	
	QualityControl.AddFilter(
		DateIsOptional,
		ObjectName + "." + TSName + ".ProductionDate",
		Undefined,
		DataCompositionComparisonType.NotFilled);
	
	QualityControl.SetupAppearance(ConditionalAppearance, Fields, FlagDisabled, DateIsOptional);
	
EndProcedure

#EndRegion

#EndRegion

#Region Queries

Function CombineRequestTextsIntoPackage(QueryTexts) Export
	
	Return StrConcat(QueryTexts, "
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|");
			
EndFunction

#EndRegion

#Region DataStructures

// Data structure of products at the production stage
// 
// Returns:
//   - ValueTable - data structure.
//
Function StageItemDataStructure() Export
	
	Result = New ValueTable;
	
	TypeDescription = New TypeDescription("CatalogRef.Products");
	Result.Columns.Add("Products", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.ItemsCharacteristics");
	Result.Columns.Add("Characteristic", TypeDescription);
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.Warehouses"));

	TypeDescription = New TypeDescription(TypesArray);
	Result.Columns.Add("Recipient", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.Assignments");
	Result.Columns.Add("Purpose", TypeDescription);
	
	TypeDescription = New TypeDescription("DocumentRef.ProductionStage2_2");
	Result.Columns.Add("StageConsumer", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure");
	Result.Columns.Add("Package", TypeDescription);
	
	Result.Columns.Add("Count");
	Result.Columns.Add("NumberOfPackages");
	
	Return Result;
	
EndFunction

// Data structure of the production stage for checking filling
// 
// Returns:
// 	Structure - LongDesc:
// * CheckingTSManufacturedProducts - Boolean - check the table part
// * CheckingTSSideAndIntermediateRelease - Boolean - check the table part
// * CheckingTSSupplyWithMaterialsAndWorks - Boolean - check the table part
// * CheckingTSMaterialsAndWorksConsumption - Boolean - check the table part
// * CheckingTSUnusedMaterials - Boolean - check the table part
// * CheckingTSLaborCosts - Boolean - check the table part
// * CheckingTSMaterialsAndWorksSets - Boolean - check the table part
// * Attributes - ValueTable - table of Attributes:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * OrderDetailsForProcessor - Structure - description of the interactively edited order to the processor:
// ** SubcontractOrder - DocumentRef.SubcontractOrder2_5 - link to the document.
// ** Status - EnumRef.TollingOrderStatuses - the Status of the order.
// ** Posted - Boolean - flag of the event.
// * ManufacturedProducts - ValueTable - Table Of Output Products:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * SideAndIntermediateRelease - ValueTable - Table Of Output Products:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * SupplyWithMaterialsAndWorks - ValueTable - table of by-products:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * MaterialsAndWorksConsumption - ValueTable - flow table:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * UnusedMaterials - ValueTable - savings table:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * LaborCosts - ValueTable - Table Of Labor Costs:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
// * MaterialsAndWorksSets - ValueTable - Table Of Labor Costs:
// ** Ref - DocumentRef.ProductionStage2_2 - link to the document
Function DataStructureOfProductionStages() Export
	
	Result = New Structure;
	
	MetadataOfDocument = Metadata.Documents.ProductionStage2_2;
	
	// Header
	Attributes = New ValueTable;
	
	For Each Attribute In MetadataOfDocument.Attributes Do
		Attributes.Columns.Add(Attribute.Name, Attribute.Type);
	EndDo;
	
	For Each Attribute In MetadataOfDocument.StandardAttributes Do
		Attributes.Columns.Add(Attribute.Name, Attribute.Type);
	EndDo;
	Result.Insert("Attributes", Attributes);
	
	// Attributes of an interactively edited order to a processor
	Result.Insert("OrderDetailsForProcessor", Undefined);
	
	// TS
	ListOfTS = New Array;
	ListOfTS.Add("ManufacturedProducts");
	ListOfTS.Add("SideAndIntermediateRelease");
	ListOfTS.Add("SupplyWithMaterialsAndWorks");
	ListOfTS.Add("MaterialsAndWorksConsumption");
	ListOfTS.Add("UnusedMaterials");
	ListOfTS.Add("LaborCosts");
	ListOfTS.Add("MaterialsAndWorksSets");
	For Each TSName In ListOfTS Do
		Result.Insert("CheckingTS" + TSName, False);
		Result.Insert(TSName, TabularPartOfDocumentProductionStage(TSName));
	EndDo;
	
	Return Result;
	
EndFunction

Function DocumentDetailsProductionStage() Export
	
	MetadataOfDocument = Metadata.Documents.ProductionStage2_2;
	
	Attributes = New Structure;
	Attributes.Insert("Ref", Documents.ProductionStage2_2.EmptyRef());
	
	For Each Attribute In MetadataOfDocument.StandardAttributes Do
		Attributes.Insert(Attribute.Name, Attribute.Type.AdjustValue(Undefined));
	EndDo;
	
	For Each Attribute In MetadataOfDocument.Attributes Do
		Attributes.Insert(Attribute.Name, Attribute.Type.AdjustValue(Undefined));
	EndDo;
	
	Return Attributes;
	
EndFunction

// Returns a table of values with the structure of the table part of the document Production2_2
//
// Parameters:
//  TSName - String - name of the table part of the document Production2_2
//
// Returns:
//  ValueTable - Contains:
//   * LineNumber - Number - 
//
Function TabularPartOfDocumentProductionStage(TSName) Export
	
	TabularSection = New ValueTable;
	MetadataOfDocument = Metadata.Documents.ProductionStage2_2;
	DescriptionOfDocumentType = New TypeDescription("DocumentRef.ProductionStage2_2");
	For Each Attribute In MetadataOfDocument.TabularSections[TSName].StandardAttributes Do
		TabularSection.Columns.Add(Attribute.Name, Attribute.Type);
	EndDo;
	For Each Attribute In MetadataOfDocument.TabularSections[TSName].Attributes Do
		TabularSection.Columns.Add(Attribute.Name, Attribute.Type);
	EndDo;
	TabularSection.Columns.Add("Ref", DescriptionOfDocumentType);
	Return TabularSection;
	
EndFunction

#EndRegion


#EndRegion

