#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Setting default parameters
	ProductDetails_5.Parameters.SetParameterValue("Scenario",Object.Scenario);
	ProductDetails_5.Parameters.SetParameterValue("PlanningPeriod",Object.BeginOfPeriod);
	ProductDetails_5.Parameters.SetParameterValue("PlanProfile",CurrentPlanKind);
	ProductDetails_5.Parameters.SetParameterValue("ConsiderOpeningBalance",False);
	ProductDetails_5.Parameters.SetParameterValue("DemandAdjustment",False);
	
	AccessRightChangePurchasePlan = AccessRight("Update", Metadata.Documents.PurchasePlan);
	AccessRightToReadThePurchasePlan = AccessRight("Read", Metadata.Documents.PurchasePlan);
	AccessRightChangeSalesPlan = AccessRight("Update", Metadata.Documents.SalesPlan);
	AccessRightToReadTheSalesPlan = AccessRight("Read", Metadata.Documents.SalesPlan);
	AccessRightToReadTheSalesPlanByCategory = AccessRight("Read", Metadata.Documents.SalesPlanByCategories);
	AccessRightsChangeTheSalesPlanByCategory = AccessRight("Update", Metadata.Documents.SalesPlanByCategories);
	AccessRightChangeAssemblyDisassemblyPlan = AccessRight("Update", Metadata.Documents.AssemblyDisassemblyPlan);
	ReadAccessRightAssemblyDisassemblyPlan = AccessRight("Read", Metadata.Documents.AssemblyDisassemblyPlan);
	AccessRightChangeProductionPlan = AccessRight("Update", Metadata.Documents.ProductionPlan);
	AccessRightReadProductionPlan = AccessRight("Read", Metadata.Documents.ProductionPlan);
	AccessRightChangeInternalConsumptionPlan = AccessRight("Update", Metadata.Documents.InventoryConsumptionPlan);
	AccessRightReadInternalConsumptionPlan = AccessRight("Read", Metadata.Documents.InventoryConsumptionPlan);
	AccessRightChangeBalancePlan = AccessRight("Update", Metadata.Documents.PlanOfGoodsStock);
	AccessRightReadBalancePlan = AccessRight("Read", Metadata.Documents.PlanOfGoodsStock);
	
	ShortageRecalculationControlTimer = 0.5;
	
	PictureBalanceOfPlans = 5;
	PictureAdjustmentsToPlannedDemands = 4;
	PicturePlansSuppliedByShortages = 3;
	PictureInitialPlans = 2;
	PictureSupplyPlanningStage = 1;
	PictureDemandPlanningStage = 0;
	
	SetConditionalAppearance();
	
	Items.PlanningStages.FixedLeft = 1;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	WhenOpenedOnServer();
	AttachIdleHandler("RecalculateStagesAndIndicators", 0.5, True);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScenarioOnChange(Item)
	ScenarioWhenChangingOnServer();
EndProcedure

&AtClient
Procedure ThePeriodBeginningEndingDuringTheChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	WhenChangingPeriodOnServer();
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export 
	WhenChangingPeriodOnServer();
EndProcedure

&AtClient
Procedure PurposeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(ProductDetails_5,
		"Purpose",
		Object.Purpose, 
		DataCompositionComparisonType.Equal,
		"Purpose",
		ValueIsFilled(Object.Purpose));
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	UpdateStageTreeOnServer();
EndProcedure

&AtClient
Procedure DecorationShowHideDetailClick(Item)
	
	Items.ProductDetails_5.Visible = Not Items.ProductDetails_5.Visible;
	
	Items.DecorationShowHideDetail.Title = ?(Items.ProductDetails_5.Visible,
		NStr("vi = 'Ẩn chi tiết';
			|ru = 'Скрыть детализацию';
			|en = 'Hide details'; fa = 'پنهان کردن جزئیات';
			|it = 'Nascondi la specifica';
			|pl = 'Ukryj szczegóły';
			|tr = 'Detaylandırmaları gizle'"),
		NStr("vi = 'Hiển thị chi tiết';
			|ru = 'Показать детализацию';
			|en = 'Show details'; fa = 'نمایش جزئیات';
			|it = 'Visualizza la specifica';
			|pl = 'Pokaż detalizację';
			|tr = 'Ayrıntıları göster'"));
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsPlanningStages

&AtClient
Procedure PlanningStagesOnActivateCell(Item)
	PlanningStagesCurData = Items.PlanningStages.CurrentData;
	
	If PlanningStagesCurData = Undefined Then
		Return;
	EndIf;
	
	If CurrentPlanKind = PlanningStagesCurData.PlanProfile
		And ThisIsAdjustment = (PlanningStagesCurData.RowPicture = 4)
		And (CurrentItemPlanningStages = Item.CurrentItem.Name
		Or Item.CurrentItem.Name = "PlanningStagesPresentation"
			And CurrentItemPlanningStages <> "PlanningStagesPresentation") Then
		Return;
	EndIf;
	CurrentItemPlanningStages = Item.CurrentItem.Name;
	CurrentPlanKind = PlanningStagesCurData.PlanProfile;
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	
	Rows = TablePeriods.FindRows(New Structure("Title",Item.CurrentItem.Title));
	If Rows.Count() > 0 Then
		PlanningPeriod = Rows[0].StartDate;
	Else
		PlanningPeriod = TablePeriods[0].StartDate;
	EndIf;
	
	ConsiderOpeningBalance = PlanningStagesCurData.StagePlanningOrder = 0 Or PlanningStagesCurData.StagePlanningOrder = 999;
	ThisIsAdjustment = PlanningStagesCurData.RowPicture = 4;
	DisplayDetails_(CurrentPlanKind, PlanningPeriod, ConsiderOpeningBalance, ThisIsAdjustment);
EndProcedure

&AtClient
Procedure PlanningStagesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	PlanningStagesCurData = Items.PlanningStages.CurrentData;
	If PlanningStagesCurData = Undefined  Then
		Return;
	EndIf;
	PlanProfile = PlanningStagesCurData.PlanProfile;
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	
	Rows = TablePeriods.FindRows(New Structure("Title",Item.CurrentItem.Title));
	If Rows.Count() > 0 Then
		BeginOfPeriod = Rows[0].StartDate;
		PeriodEnding = Rows[0].EndDate;
	Else
		ShowValue(,PlanProfile);
		Return;
	EndIf;
	
	If PlanningStagesCurData.AccessRightUpdate 
		And PlanningStagesCurData["State_" + Rows[0].ColumnName] = 1 Then
		
		ArrayTypesOfPlans = New Array;
		
		If PlanningStagesCurData.IsFolder Then
			For Each PlanViewElement_ In PlanningStages.FindByID(RowSelected).GetItems() Do
				If PlanViewElement_.FillInByShortage Then
					ArrayTypesOfPlans.Add(PlanViewElement_.PlanProfile);
				EndIf;
			EndDo;
		Else
			ArrayTypesOfPlans.Add(PlanProfile);
		EndIf;
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("Scenario", Object.Scenario);
		ProcedureParameters.Insert("Periodicity", Object.Periodicity);
		ProcedureParameters.Insert("PlanProfiles", ArrayTypesOfPlans);
		ProcedureParameters.Insert("BeginOfPeriod", BeginOfPeriod); 
		ProcedureParameters.Insert("PeriodEnding", PeriodEnding);
		
		RunBackgroundJob1(
			"FillPlansByShortagesBeforeColumn",
			ProcedureParameters);
			
		Return;
	EndIf;
	
	If PlanningStagesCurData.AccessRightRead Then
		ListOfPlanProfiles = TypesOfPlansForSelection(Items.PlanningStages.CurrentRow);
		
		FormParameters = New Structure();
		FormParameters.Insert("Scenario", Object.Scenario);
		FormParameters.Insert("PlanProfile", PlanProfile);
		FormParameters.Insert("ListOfPlanProfiles", ListOfPlanProfiles);
		FormParameters.Insert("Products", Undefined);
		FormParameters.Insert("Characteristic", Undefined);
		FormParameters.Insert("Purpose", Undefined);
		FormParameters.Insert("BeginOfPeriod", BeginOfPeriod);
		FormParameters.Insert("PeriodEnding", PeriodEnding);
		FormParameters.Insert("DataType", "");
		
		OpenForm("DataProcessor.PlanningProcessManagement.Form.FormOfDocuments", FormParameters, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersProductDetails

&AtClient
Procedure ProductDetails_5Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not (Field.Name = "ProductDetails_5OpeningBalance"
		Or Field.Name = "ProductDetails_5Receipt"
		Or Field.Name = "ProductDetails_5Expense"
		Or Field.Name = "ProductDetails_5ExpenseAdjustment"
		Or Field.Name = "ProductDetails_5Products"
		Or Field.Name = "ProductDetails_5Characteristic"
		Or Field.Name = "ProductDetails_5Purpose") Then
		Return;
	EndIf;
	
	PlanningStagesCurData = Items.PlanningStages.CurrentData;
	ProductDetailsCurData = Items.ProductDetails_5.CurrentData;
	If PlanningStagesCurData = Undefined
		Or ProductDetailsCurData = Undefined Then
		Return;
	EndIf;
	
	If (Field.Name = "ProductDetails_5Products"
		Or Field.Name = "ProductDetails_5Characteristic"
		Or Field.Name = "ProductDetails_5Purpose") Then
		ShowValue(,ProductDetailsCurData.Products);
		Return;
	EndIf;
	
	PlanProfile = PlanningStagesCurData.PlanProfile;
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	
	Rows = TablePeriods.FindRows(New Structure("Title", Items.PlanningStages.CurrentItem.Title));
	If Rows.Count() > 0 Then
		BeginOfPeriod = Rows[0].StartDate;
		PeriodEnding = Rows[0].EndDate;
	Else
		BeginOfPeriod = TablePeriods[0].StartDate;
		PeriodEnding = TablePeriods[0].EndDate;
	EndIf;
	
	Products = ProductDetailsCurData.Products;
	Characteristic = ?(ProductDetailsCurData.Property("Characteristic"),
						ProductDetailsCurData.Characteristic,
						PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	
	If ProductDetailsCurData.Property("Purpose") Then
		Purpose = ProductDetailsCurData.Purpose;
	Else
		Purpose = PredefinedValue("Catalog.Assignments.EmptyRef");
	EndIf;
	DataType = StrReplace(Field.Name, "ProductDetails_5", "");
	
	ListOfPlanProfiles = TypesOfPlansForSelection(Items.PlanningStages.CurrentRow);
	
	FormParameters = New Structure();
	FormParameters.Insert("Scenario", Object.Scenario);
	FormParameters.Insert("PlanProfile", PlanProfile);
	FormParameters.Insert("ListOfPlanProfiles", ListOfPlanProfiles);
	FormParameters.Insert("Products", Products);
	FormParameters.Insert("Characteristic", Characteristic);
	FormParameters.Insert("Purpose", Purpose);
	FormParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	FormParameters.Insert("PeriodEnding", PeriodEnding);
	FormParameters.Insert("DataType", ?(Field.Name = "ProductDetails_5ExpenseAdjustment", "ExpenseAdjustment", DataType));
	
	OpenForm("DataProcessor.PlanningProcessManagement.Form.FormOfDocuments", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription(
		"SetDateIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "PeriodEnding"),
		Notification);
	
EndProcedure

&AtClient
Procedure RecalculateToColumn(Command)
	PlanningStagesCurData = Items.PlanningStages.CurrentData;
	RowSelected = Items.PlanningStages.CurrentRow;
	If PlanningStagesCurData = Undefined
		Or (Not PlanningStagesCurData.IsFolder And Not PlanningStagesCurData.FillInByShortage) Then
		Return;
	EndIf;
	PlanProfile = PlanningStagesCurData.PlanProfile;
	
	TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
	
	Rows = TablePeriods.FindRows(New Structure("Title", Items.PlanningStages.CurrentItem.Title));
	If Rows.Count() > 0 Then
		PeriodEnding = Rows[0].EndDate;
	Else
		Return;
	EndIf;
	
	ArrayTypesOfPlans = New Array;
	ArrayPeriods = New Array;
	
	If PlanningStagesCurData.IsFolder Then
		For Each PlanViewElement_ In PlanningStages.FindByID(RowSelected).GetItems() Do
			If PlanViewElement_.FillInByShortage Then
				ArrayTypesOfPlans.Add(PlanViewElement_.PlanProfile);
			EndIf;
		EndDo;
	Else
		ArrayTypesOfPlans.Add(PlanProfile);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Scenario", Object.Scenario);
	ProcedureParameters.Insert("Periodicity", Object.Periodicity);
	ProcedureParameters.Insert("PlanProfiles", ArrayTypesOfPlans);
	ProcedureParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod); 
	ProcedureParameters.Insert("PeriodEnding", PeriodEnding);
	
	RunBackgroundJob1(
		"FillPlansByShortagesBeforeColumn",
		ProcedureParameters);
	
EndProcedure

&AtClient
Procedure RecalculateAllPeriods(Command)
	PlanningStagesCurData = Items.PlanningStages.CurrentData;
	RowSelected = Items.PlanningStages.CurrentRow;
	If PlanningStagesCurData = Undefined
		Or (Not PlanningStagesCurData.IsFolder And Not PlanningStagesCurData.FillInByShortage) Then
		Return;
	EndIf;
	PlanProfile = PlanningStagesCurData.PlanProfile;
	
	ArrayTypesOfPlans = New Array;
	ArrayPeriods = New Array;
	
	If PlanningStagesCurData.IsFolder Then
		For Each PlanViewElement_ In PlanningStages.FindByID(RowSelected).GetItems() Do
			If PlanViewElement_.FillInByShortage Then
				ArrayTypesOfPlans.Add(PlanViewElement_.PlanProfile);
			EndIf;
		EndDo;
	Else
		ArrayTypesOfPlans.Add(PlanProfile);
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Scenario", Object.Scenario);
	ProcedureParameters.Insert("Periodicity", Object.Periodicity);
	ProcedureParameters.Insert("PlanProfiles", ArrayTypesOfPlans);
	ProcedureParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod); 
	ProcedureParameters.Insert("PeriodEnding", Object.PeriodEnding);
	
	RunBackgroundJob1(
		"FillPlansByShortagesInAllPeriods",
		ProcedureParameters);
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	ShortageRecalculationControlTimer = 0.5;
	RecalculateStagesAndIndicators();
	
EndProcedure

&AtClient
Procedure RecalculateShortages(Command)
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("Scenario", Object.Scenario);
	
	RunBackgroundJob1(
		"RunTheRecalculationOfShortagesInStagesForAllThePeriods",
		ProcedureParameters);
EndProcedure
	
#EndRegion

#Region Private

&AtClient
Procedure RecalculateStagesAndIndicators()
	UpdateStageTree();
	ShortageRecalculationControlTimer = Min(ShortageRecalculationControlTimer*1.5, 60);
	AttachIdleHandler("RecalculateStagesAndIndicators", ShortageRecalculationControlTimer, True);
EndProcedure

&AtServer
Procedure WhenOpenedOnServer()
	Planning.CreatePeriodTable(ThisForm, "TimeIntervals");
	ScenarioWhenChangingOnServer();
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField("PlanningStagesPresentation");
	
	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.AccessRightRead");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.FilterByResponsibleEmployee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtClient
Function GetListOfPlanTypesToSelect(CurrentRow)
	
	TreeItem = PlanningStages.FindByID(CurrentRow);
	ListOfPlanProfiles = New Array;
	
	If TreeItem.IsFolder Then
		For Each Item In TreeItem.GetItems() Do
			ListOfPlanProfiles.Add(Item.PlanProfile);
		EndDo;
	Else
		ListOfPlanProfiles.Add(TreeItem.PlanProfile);
	EndIf;
	
	Return ListOfPlanProfiles
	
EndFunction

&AtClient
Function TypesOfPlansForSelection(CurrentRow)
	
	TreeItem = PlanningStages.FindByID(CurrentRow);
	ListOfPlanProfiles = New Array;
	
	If TreeItem.IsFolder Then
		For Each Item In TreeItem.GetItems() Do
			ListOfPlanProfiles.Add(Item.PlanProfile);
		EndDo;
	Else
		ListOfPlanProfiles.Add(TreeItem.PlanProfile);
	EndIf;
	
	Return ListOfPlanProfiles
	
EndFunction

&AtServer
Procedure ScenarioWhenChangingOnServer()
	ScriptDetails = Common.ObjectAttributesValues(Object.Scenario, "Periodicity, PlanningByAssignments, ShowNumberOfPeriod");
	Object.Periodicity = ScriptDetails.Periodicity;
	PlanningByAssignments = ScriptDetails.PlanningByAssignments;
	ShowNumberOfPeriod = ScriptDetails.ShowNumberOfPeriod;
	
	WhenChangingPeriodOnServer();
	SetVisibility1();
EndProcedure

&AtServer
Procedure WhenChangingPeriodOnServer()
	
	If Not ValueIsFilled(Object.Scenario) Then
		Return;
	EndIf;
	
	PlanningClientServer.SetStartEndOfPlanPeriod(Object.Periodicity, Object.BeginOfPeriod, Object.PeriodEnding, CurrentSessionDate());
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	Planning.FillInPeriodTable(TablePeriods, Object.Periodicity, Object.BeginOfPeriod, Object.PeriodEnding, ShowNumberOfPeriod);
	ValueToFormAttribute(TablePeriods,"TimeIntervals");
	UpdateStructureOfPlanningStagesByPeriod(TablePeriods);
	UpdateStageTreeOnServer();
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.Purpose.Visible = PlanningByAssignments;
	Items.ProductDetails_5Purpose.Visible = PlanningByAssignments;
	
EndProcedure


// LongDesc
// 
// Parameters:
// 	PeriodsTable See Planning.TablePeriods
&AtServer
Procedure UpdateStructureOfPlanningStagesByPeriod(PeriodsTable)
	
	PropsNamePlanningStages = "PlanningStages";
	FormElementPlanningStages = "PlanningStages";
	Periodicity = Object.Periodicity;
	Fields = New Array();
	
	Fields.Add(FieldStructureConstructor("Status_", TMCommonUse.GetDescriptionOfNumberTypes(15, 2), False));
	Fields.Add(FieldStructureConstructor("State_", TMCommonUse.GetDescriptionOfNumberTypes(15, 2), True));
	
	AttributesToBeAdded = New Array();
	AttributesToBeDeleted = New Array();
	PropsAndStagesOfTinting = ThisForm.GetAttributes(PropsNamePlanningStages);
	TopLevelDetails = ThisForm.GetAttributes();
	
	For Each Attribute In PropsAndStagesOfTinting Do
		If StrFind(Attribute.Name, "State_") <> 0 Or StrFind(Attribute.Name, "Status_") <> 0 Then
			AttributesToBeDeleted.Add(PropsNamePlanningStages+"." + Attribute.Name);
		EndIf;
	EndDo;
	
	For Each FieldStructure In Fields Do //See FieldStructureConstructor
		
		ColumnAttributePrefix = FieldStructure.ColumnAttributePrefix;
		
		// Details that cannot be deleted
		For Each PeriodString_ In PeriodsTable Do
			
			IndexOfElementToDelete = AttributesToBeDeleted.Find(PropsNamePlanningStages+"." + ColumnAttributePrefix + PeriodString_.ColumnName);
			If IndexOfElementToDelete <> Undefined Then
				AttributesToBeDeleted.Delete(IndexOfElementToDelete);
			EndIf;
			
		EndDo;
		
		ElementType = FieldStructure.ElementType;
		TypeDescription = ElementType;
		
		// Creating table details
		For Each PeriodString_ In PeriodsTable Do
		
			PropsExist = False;
			For Each Attribute In PropsAndStagesOfTinting Do
				If Attribute.Name = ColumnAttributePrefix + PeriodString_.ColumnName Then
					PropsExist = True;
					Break;
				EndIf;
			EndDo;
			If PropsExist Then
				Attribute.Title = PeriodString_.Title;
				
				Continue;
			EndIf; 
			
			Attribute = New FormAttribute(ColumnAttributePrefix + PeriodString_.ColumnName, TypeDescription, PropsNamePlanningStages,
				PeriodString_.Title);
			AttributesToBeAdded.Add(Attribute);
		EndDo;
		
	EndDo;
	
	ThisForm.ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);
	
	// Deleting Form elements
	ItemsToRemove = New Array();
	For Each CurItem In ThisForm.Items.PlanningStages.ChildItems Do
		If StrFind(CurItem.Name, FormElementPlanningStages + "AttributeGroup") Then
			ItemsToRemove.Add(CurItem);
			Continue;
		EndIf;
		ElementFound_ = False;
		For Each PeriodString_ In PeriodsTable Do
			If  StrFind(CurItem.Name, FormElementPlanningStages + "Group"+PeriodString_.ColumnName) Then
				ItemsToRemove.Add(CurItem);
				ElementFound_ = True;
				Break;
			EndIf;
		EndDo;
		If ElementFound_ Then
			Continue;
		EndIf; 
		For Each FieldStructure In Fields Do
			ColumnAttributePrefix = FieldStructure.ColumnAttributePrefix;
			If StrFind(CurItem.Name, ColumnAttributePrefix) > 0  Then
				ItemsToRemove.Add(CurItem);
				Break;
			EndIf;
		EndDo;
	EndDo;
	For Each ItemToRemove In ItemsToRemove Do
		ThisForm.Items.Delete(ItemToRemove);
	EndDo;
	
	FieldOwner = ThisForm.Items[FormElementPlanningStages];
	
	For Each PeriodString_ In PeriodsTable Do
		If Not PeriodString_.Active_ Then
			Continue;
		EndIf; 
				
		For Each FieldStructure In Fields Do
			ColumnAttributePrefix = FieldStructure.ColumnAttributePrefix;
			
			CreateElement_ = FieldStructure.CreateElement_;
			If Not CreateElement_ Then
				Continue;
			EndIf;
			
			// Re-linking the data
			// Creating Form elements
			Item = ThisForm.Items.Add(FormElementPlanningStages + ColumnAttributePrefix + PeriodString_.ColumnName, 
				Type("FormField"), FieldOwner);
			Item.Type = FormFieldType.PictureField;
			Item.ValuesPicture = PictureLib.PlanningOfActionSteps;
			Item.DataPath = PropsNamePlanningStages+"."+ColumnAttributePrefix + PeriodString_.ColumnName;
			Item.Width = 2;
			
			Item.Title = PeriodString_.Title;
			
			AddConditionalAppearanceForColumn(Item.Name, PeriodString_.ColumnName);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Constructor of the field structure.
// 
// Parameters:
//  ColumnAttributePrefix - String - 
//  ElementType - TypeDescription - 
//  CreateElement_ - Boolean - 
// 
// Returns:
//  Structure - Field Structure:
// * ColumnAttributePrefix - String
// * ElementType - TypeDescription
// * CreateElement_ - Boolean
&AtServer
Function FieldStructureConstructor(ColumnAttributePrefix, ElementType, CreateElement_)
	
	FieldStructure = New Structure;
	FieldStructure.Insert("ColumnAttributePrefix", ColumnAttributePrefix);
	FieldStructure.Insert("ElementType", ElementType);
	FieldStructure.Insert("CreateElement_", CreateElement_);
	
	Return FieldStructure;
EndFunction

&AtServer
Procedure AddConditionalAppearanceForColumn(ItemName,ColumnName)
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.Status_"+ColumnName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("BackColor", WebColors.DeepSkyBlue);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.Status_"+ColumnName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	
	Item.Appearance.SetParameterValue("BackColor", WebColors.DodgerBlue);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.Status_"+ColumnName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 3;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.AccentColor);

	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.Status_"+ColumnName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 5;
	
	Item.Appearance.SetParameterValue("BackColor", WebColors.LightSkyBlue);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.Status_"+ColumnName);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 6;
	
	Item.Appearance.SetParameterValue("BackColor", StyleColors.AccentColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.AccessRightRead");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(ItemName);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PlanningStages.FilterByResponsibleEmployee");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	
EndProcedure

&AtServer
Function UpdateStageTreeOnServer()
	
	Query = New Query();
	
	Query.Text =
	"SELECT
	|	TablePeriods.StartDate AS PlanningPeriod,
	|	CAST(TablePeriods.ColumnName AS STRING(36)) AS ColumnName
	|INTO TablePeriods
	|FROM
	|	&TablePeriods AS TablePeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanProfiles.Ref AS PlanProfile,
	|	PlanProfiles.PlanningProcedure AS PlanningProcedure,
	|	ISNULL(PlanProfiles.Parent.PlanningProcedure, PlanProfiles.PlanningProcedure) AS StagePlanningOrder,
	|	CASE
	|		WHEN PlanProfiles.Parent.PlanningProcedure IS NULL
	|			THEN PlanProfiles.Ref
	|		ELSE PlanProfiles.Parent
	|	END AS PlanningStage,
	|	PlanProfiles.IsFolder AS IsFolder,
	|	ISNULL(PlanProfiles.FillInByShortage, FALSE) AS FillInByShortage,
	|	CASE
	|		WHEN PlanProfiles.IsFolder
	|			THEN CASE
	|				WHEN PlanProfiles.DeletionMark
	|					THEN 6
	|				ELSE CASE
	|					WHEN PlanProfiles.DemandPlanning
	|						THEN 0
	|					ELSE 1
	|				END
	|			END
	|		ELSE CASE
	|			WHEN PlanProfiles.DeletionMark
	|				THEN 7
	|			ELSE CASE
	|				WHEN PlanProfiles.Parent = VALUE(Catalog.PlanProfiles.EmptyRef)
	|				AND PlanProfiles.PlanType <> VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|					THEN 8
	|				WHEN PlanProfiles.FillInByShortage
	|					THEN 3
	|				ELSE 2
	|			END
	|		END
	|	END AS RowPicture,
	|	TablePeriods.PlanningPeriod AS PlanningPeriod,
	|	TablePeriods.ColumnName AS ColumnName,
	|	FALSE AS Adjusting,
	|	CASE
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|			THEN &AccessRightChangePurchasePlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|			THEN &AccessRightChangeSalesPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlanByCategories)
	|			THEN &AccessRightsChangeTheSalesPlanByCategory
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|			THEN &AccessRightChangeAssemblyDisassemblyPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|			THEN &AccessRightChangeProductionPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.InventoryConsumptionPlan)
	|			THEN &AccessRightChangeInternalConsumptionPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|			THEN &AccessRightChangeBalancePlan
	|		ELSE FALSE
	|	END AS AccessRightUpdate,
	|	CASE
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PurchasePlan)
	|			THEN &AccessRightToReadThePurchasePlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlan)
	|			THEN &AccessRightToReadTheSalesPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.SalesPlanByCategories)
	|			THEN &AccessRightToReadTheSalesPlanByCategory
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.AssemblyDisassemblyPlan)
	|			THEN &ReadAccessRightAssemblyDisassemblyPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.ProductionPlan)
	|			THEN &AccessRightReadProductionPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.InventoryConsumptionPlan)
	|			THEN &AccessRightReadInternalConsumptionPlan
	|		WHEN PlanProfiles.PlanType = VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|			THEN &AccessRightReadBalancePlan
	|		ELSE FALSE
	|	END AS AccessRightRead,
	|	NOT &FilterEmployeeResponsible
	|	OR PlanProfiles.EmployeeResponsible = &EmployeeResponsible
	|	OR PlanProfiles.EmployeeResponsible = VALUE(Catalog.Users.EmptyRef) AS FilterByResponsibleEmployee
	|INTO PlansStructure
	|FROM
	|	Catalog.PlanProfiles AS PlanProfiles,
	|	TablePeriods AS TablePeriods
	|WHERE
	|	PlanProfiles.Owner = &Scenario
	|	AND
	|	NOT PlanProfiles.DeletionMark
	|	AND
	|	NOT (PlanProfiles.PlanType <> VALUE(Enum.TypesOfPlans.PlanOfGoodsStock)
	|	AND PlanProfiles.Parent = VALUE(Catalog.PlanProfiles.EmptyRef)
	|	AND
	|	NOT PlanProfiles.IsFolder)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.PlanProfiles.EmptyRef),
	|	999,
	|	999,
	|	VALUE(Catalog.PlanProfiles.EmptyRef),
	|	TRUE,
	|	FALSE,
	|	5,
	|	TablePeriods.PlanningPeriod,
	|	TablePeriods.ColumnName,
	|	FALSE,
	|	TRUE,
	|	TRUE,
	|	TRUE
	|FROM
	|	TablePeriods AS TablePeriods
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	AdjustmentOfPlannedDemand.PlanProfile,
	|	AdjustmentOfPlannedDemand.PlanProfile.PlanningProcedure,
	|	ISNULL(AdjustmentOfPlannedDemand.PlanProfile.Parent.PlanningProcedure,
	|		AdjustmentOfPlannedDemand.PlanProfile.PlanningProcedure),
	|	CASE
	|		WHEN AdjustmentOfPlannedDemand.PlanProfile.Parent.PlanningProcedure IS NULL
	|			THEN AdjustmentOfPlannedDemand.PlanProfile
	|		ELSE AdjustmentOfPlannedDemand.PlanProfile.Parent
	|	END,
	|	FALSE,
	|	FALSE,
	|	4,
	|	TablePeriods.PlanningPeriod,
	|	TablePeriods.ColumnName,
	|	TRUE,
	|	TRUE,
	|	TRUE,
	|	TRUE
	|FROM
	|	Document.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand,
	|	TablePeriods AS TablePeriods
	|WHERE
	|	AdjustmentOfPlannedDemand.Scenario = &Scenario
	|	AND AdjustmentOfPlannedDemand.Posted
	|	AND AdjustmentOfPlannedDemand.Period >= &BeginOfPeriod
	|	AND AdjustmentOfPlannedDemand.Period <= &PeriodEnding
	|	AND AdjustmentOfPlannedDemand.Status <> VALUE(Enum.StatusesOfPlanAdjustments.RolledBack)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfPlanShortagesByStages.PlanProfile AS PlanProfile,
	|	CalculationOfPlanShortagesByStages.PlanningPeriod AS PlanningPeriod,
	|	CASE
	|		WHEN CalculationOfPlanShortagesByStages.ShouldRecalculate
	|			THEN 1
	|		ELSE 0
	|	END AS State
	|INTO CalculationOfShortagesInStages
	|FROM
	|	InformationRegister.CalculationOfPlanShortagesByStages AS CalculationOfPlanShortagesByStages,
	|	TablePeriods AS TablePeriods
	|WHERE
	|	CalculationOfPlanShortagesByStages.PlanningPeriod BETWEEN &BeginOfPeriod AND &PeriodEnding
	|	AND CalculationOfPlanShortagesByStages.Products = VALUE(Catalog.Products.EmptyRef)
	|	AND CalculationOfPlanShortagesByStages.Scenario = &Scenario
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchasePlan.PlanProfile AS PlanProfile,
	|	MIN(PurchasePlan.Status.Order) AS StatusOrder,
	|	TablePeriods.PlanningPeriod AS PlanningPeriod,
	|	FALSE AS Adjusting
	|INTO Statuses_Document
	|FROM
	|	Document.PurchasePlan AS PurchasePlan
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON PurchasePlan.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|		AND PurchasePlan.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	PurchasePlan.Posted
	|	AND PurchasePlan.Scenario = &Scenario
	|	AND PurchasePlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND
	|	NOT PurchasePlan.DeletionMark
	|	AND PurchasePlan.BeginOfPeriod <= &PeriodEnding
	|	AND PurchasePlan.PeriodEnding >= &BeginOfPeriod
	|GROUP BY
	|	PurchasePlan.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	SalesPlan.PlanProfile,
	|	MIN(SalesPlan.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	FALSE
	|FROM
	|	Document.SalesPlan AS SalesPlan
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON SalesPlan.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|		AND SalesPlan.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	SalesPlan.Posted
	|	AND SalesPlan.Scenario = &Scenario
	|	AND SalesPlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND
	|	NOT SalesPlan.DeletionMark
	|	AND SalesPlan.BeginOfPeriod <= &PeriodEnding
	|	AND SalesPlan.PeriodEnding >= &BeginOfPeriod
	|GROUP BY
	|	SalesPlan.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	SalesPlanByCategories.PlanProfile,
	|	MIN(SalesPlanByCategories.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	FALSE
	|FROM
	|	Document.SalesPlanByCategories AS SalesPlanByCategories
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON SalesPlanByCategories.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|		AND SalesPlanByCategories.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	SalesPlanByCategories.Posted
	|	AND SalesPlanByCategories.Scenario = &Scenario
	|	AND SalesPlanByCategories.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND
	|	NOT SalesPlanByCategories.DeletionMark
	|	AND SalesPlanByCategories.BeginOfPeriod <= &PeriodEnding
	|	AND SalesPlanByCategories.PeriodEnding >= &BeginOfPeriod
	|GROUP BY
	|	SalesPlanByCategories.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyDisassemblyPlan.PlanProfile,
	|	MIN(AssemblyDisassemblyPlan.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	FALSE
	|FROM
	|	Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON AssemblyDisassemblyPlan.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|		AND AssemblyDisassemblyPlan.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	AssemblyDisassemblyPlan.Posted
	|	AND AssemblyDisassemblyPlan.Scenario = &Scenario
	|	AND
	|	NOT AssemblyDisassemblyPlan.DeletionMark
	|	AND AssemblyDisassemblyPlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND AssemblyDisassemblyPlan.BeginOfPeriod <= &PeriodEnding
	|	AND AssemblyDisassemblyPlan.PeriodEnding >= &BeginOfPeriod
	|GROUP BY
	|	AssemblyDisassemblyPlan.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	ProductionPlan.PlanProfile,
	|	MIN(ProductionPlan.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	FALSE
	|FROM
	|	Document.ProductionPlan AS ProductionPlan
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON ProductionPlan.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|		AND ProductionPlan.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	ProductionPlan.Posted
	|	AND ProductionPlan.Scenario = &Scenario
	|	AND
	|	NOT ProductionPlan.DeletionMark
	|	AND ProductionPlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND ProductionPlan.BeginOfPeriod <= &PeriodEnding
	|	AND ProductionPlan.PeriodEnding >= &BeginOfPeriod
	|GROUP BY
	|	ProductionPlan.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryConsumptionPlan.PlanProfile,
	|	MIN(InventoryConsumptionPlan.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	FALSE
	|FROM
	|	Document.InventoryConsumptionPlan AS InventoryConsumptionPlan
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON InventoryConsumptionPlan.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|			AND InventoryConsumptionPlan.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	InventoryConsumptionPlan.Posted
	|	AND InventoryConsumptionPlan.Scenario = &Scenario
	|	AND InventoryConsumptionPlan.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND NOT InventoryConsumptionPlan.DeletionMark
	|	AND InventoryConsumptionPlan.BeginOfPeriod <= &PeriodEnding
	|	AND InventoryConsumptionPlan.PeriodEnding >= &BeginOfPeriod
	|
	|GROUP BY
	|	InventoryConsumptionPlan.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	PlanOfGoodsStock.PlanProfile,
	|	MIN(PlanOfGoodsStock.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	FALSE
	|FROM
	|	Document.PlanOfGoodsStock AS PlanOfGoodsStock
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON PlanOfGoodsStock.BeginOfPeriod <= TablePeriods.PlanningPeriod
	|		AND PlanOfGoodsStock.PeriodEnding >= TablePeriods.PlanningPeriod
	|WHERE
	|	PlanOfGoodsStock.Posted
	|	AND PlanOfGoodsStock.Scenario = &Scenario
	|	AND PlanOfGoodsStock.Status <> VALUE(Enum.PlanStatuses.RolledBack_)
	|	AND
	|	NOT PlanOfGoodsStock.DeletionMark
	|	AND PlanOfGoodsStock.BeginOfPeriod <= &PeriodEnding
	|	AND PlanOfGoodsStock.PeriodEnding >= &BeginOfPeriod
	|GROUP BY
	|	PlanOfGoodsStock.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|
	|UNION ALL
	|
	|SELECT
	|	AdjustmentOfPlannedDemand.PlanProfile,
	|	MIN(AdjustmentOfPlannedDemand.Status.Order),
	|	TablePeriods.PlanningPeriod,
	|	TRUE
	|FROM
	|	Document.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand
	|		LEFT JOIN TablePeriods AS TablePeriods
	|		ON AdjustmentOfPlannedDemand.Period <= TablePeriods.PlanningPeriod
	|		AND AdjustmentOfPlannedDemand.Period >= TablePeriods.PlanningPeriod
	|WHERE
	|	AdjustmentOfPlannedDemand.Posted
	|	AND AdjustmentOfPlannedDemand.Scenario = &Scenario
	|	AND AdjustmentOfPlannedDemand.Status <> VALUE(Enum.StatusesOfPlanAdjustments.RolledBack)
	|	AND
	|	NOT AdjustmentOfPlannedDemand.DeletionMark
	|	AND AdjustmentOfPlannedDemand.Period <= &PeriodEnding
	|	AND AdjustmentOfPlannedDemand.Period >= &BeginOfPeriod
	|GROUP BY
	|	AdjustmentOfPlannedDemand.PlanProfile,
	|	TablePeriods.PlanningPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses_Document.PlanProfile AS PlanProfile,
	|	Statuses_Document.StatusOrder AS StatusOrder,
	|	Statuses_Document.PlanningPeriod AS PlanningPeriod,
	|	Statuses_Document.Adjusting AS Adjusting,
	|	PlanProfiles.Parent AS PlanningStage
	|INTO DocumentStatusAndStages
	|FROM
	|	Statuses_Document AS Statuses_Document
	|		LEFT JOIN Catalog.PlanProfiles AS PlanProfiles
	|		ON Statuses_Document.PlanProfile = PlanProfiles.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlansStructure.PlanProfile AS PlanProfile,
	|	PRESENTATION(PlansStructure.PlanProfile) AS Presentation,
	|	PlansStructure.PlanningProcedure AS PlanningProcedure,
	|	PlansStructure.StagePlanningOrder AS StagePlanningOrder,
	|	PlansStructure.PlanningStage AS PlanningStage,
	|	PlansStructure.IsFolder AS IsFolder,
	|	PlansStructure.FillInByShortage AS FillInByShortage,
	|	PlansStructure.PlanningPeriod AS PlanningPeriod,
	|	PlansStructure.RowPicture AS RowPicture,
	|	ISNULL(Statuses_Document.StatusOrder, 0) AS StatusOrderForGrouping,
	|	MIN(CASE
	|		WHEN PlansStructure.IsFolder
	|			THEN ISNULL(Statuses_Document1.StatusOrder, 9)
	|		ELSE CASE
	|			WHEN PlansStructure.RowPicture = 4
	|				THEN ISNULL(Statuses_Document.StatusOrder, 9) + 4
	|			ELSE ISNULL(Statuses_Document.StatusOrder, 9)
	|		END
	|	END) AS StatusOrder,
	|	CASE
	|		WHEN PlansStructure.RowPicture = 4
	|			THEN CASE
	|				WHEN ISNULL(Statuses_Document.StatusOrder, 0) = 1
	|					THEN 2
	|				ELSE 0
	|			END
	|		ELSE CalculationOfShortagesInStages.State
	|	END AS State,
	|	PlansStructure.ColumnName AS ColumnName,
	|	MAX(ISNULL(StructureOfLawPlans.AccessRightUpdate, PlansStructure.AccessRightUpdate)) AS
	|		AccessRightUpdate,
	|	MAX(ISNULL(StructureOfLawPlans.AccessRightRead, PlansStructure.AccessRightRead)) AS
	|		AccessRightRead,
	|	MAX(ISNULL(StructureOfLawPlans.FilterByResponsibleEmployee, PlansStructure.FilterByResponsibleEmployee)) AS
	|		FilterByResponsibleEmployee,
	|	PlansStructure.PlanProfile.PlanType AS PlanProfilePlanType,
	|	PlansStructure.PlanProfile.Description AS PlanProfileName,
	|	PlansStructure.PlanProfile.NumberOfPeriods AS PlanProfileQuantityOfPeriods,
	|	PlansStructure.PlanningStage.Description AS PlanningStageName
	|INTO NewPlanningStages
	|FROM
	|	PlansStructure AS PlansStructure
	|		LEFT JOIN CalculationOfShortagesInStages AS CalculationOfShortagesInStages
	|		ON PlansStructure.PlanProfile = CalculationOfShortagesInStages.PlanProfile
	|		AND PlansStructure.PlanningPeriod = CalculationOfShortagesInStages.PlanningPeriod
	|		LEFT JOIN DocumentStatusAndStages AS Statuses_Document
	|		ON PlansStructure.PlanProfile = Statuses_Document.PlanProfile
	|		AND PlansStructure.PlanningPeriod = Statuses_Document.PlanningPeriod
	|		AND PlansStructure.Adjusting = Statuses_Document.Adjusting
	|		LEFT JOIN DocumentStatusAndStages AS Statuses_Document1
	|		ON PlansStructure.PlanningPeriod = Statuses_Document1.PlanningPeriod
	|		AND PlansStructure.PlanProfile = Statuses_Document1.PlanningStage
	|		AND PlansStructure.Adjusting = Statuses_Document1.Adjusting
	|		LEFT JOIN PlansStructure AS StructureOfLawPlans
	|		ON PlansStructure.PlanProfile = StructureOfLawPlans.PlanningStage
	|		AND PlansStructure.PlanProfile <> StructureOfLawPlans.PlanProfile
	|GROUP BY
	|	PlansStructure.IsFolder,
	|	PlansStructure.PlanProfile,
	|	PlansStructure.PlanningPeriod,
	|	PlansStructure.PlanningStage,
	|	PlansStructure.FillInByShortage,
	|	PlansStructure.PlanningProcedure,
	|	PlansStructure.StagePlanningOrder,
	|	PlansStructure.RowPicture,
	|	PlansStructure.ColumnName,
	|	CalculationOfShortagesInStages.State,
	|	ISNULL(Statuses_Document.StatusOrder, 0),
	|	CASE
	|		WHEN PlansStructure.RowPicture = 4
	|			THEN CASE
	|				WHEN ISNULL(Statuses_Document.StatusOrder, 0) = 1
	|					THEN 2
	|				ELSE 0
	|			END
	|		ELSE CalculationOfShortagesInStages.State
	|	END,
	|	PlansStructure.PlanProfile.PlanType,
	|	PlansStructure.PlanProfile.Description,
	|	PlansStructure.PlanProfile.NumberOfPeriods,
	|	PlansStructure.PlanningStage.Description
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PlanningStagesTable.PlanProfile AS PlanProfile,
	|	PlanningStagesTable.Presentation AS Presentation,
	|	PlanningStagesTable.PlanningProcedure AS PlanningProcedure,
	|	PlanningStagesTable.StagePlanningOrder AS StagePlanningOrder,
	|	PlanningStagesTable.PlanningStage AS PlanningStage,
	|	PlanningStagesTable.IsFolder AS IsFolder,
	|	PlanningStagesTable.FillInByShortage AS FillInByShortage,
	|	PlanningStagesTable.PlanningPeriod AS PlanningPeriod,
	|	PlanningStagesTable.RowPicture AS RowPicture,
	|	PlanningStagesTable.StatusOrder AS StatusOrder,
	|	PlanningStagesTable.State AS State,
	|	PlanningStagesTable.FilterByResponsibleEmployee AS FilterByResponsibleEmployee
	|INTO PlanningStagesAreOld
	|FROM
	|	&PlanningStagesTable AS PlanningStagesTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(NewPlanningStages.PlanProfile,
	|		VALUE(Catalog.PlanProfiles.EmptyRef)) <> ISNULL(PlanningStagesAreOld.PlanProfile,
	|		VALUE(Catalog.PlanProfiles.EmptyRef))
	|	OR ISNULL(NewPlanningStages.PlanningProcedure, 99) <> ISNULL(PlanningStagesAreOld.PlanningProcedure,
	|		99)
	|	OR ISNULL(NewPlanningStages.StagePlanningOrder,
	|		99) <> ISNULL(PlanningStagesAreOld.StagePlanningOrder, 99)
	|	OR ISNULL(NewPlanningStages.FillInByShortage,
	|		FALSE) <> ISNULL(PlanningStagesAreOld.FillInByShortage, FALSE) AS StructureHasChanged,
	|	ISNULL(NewPlanningStages.State, 0) <> ISNULL(PlanningStagesAreOld.State, 0)
	|	OR ISNULL(NewPlanningStages.StatusOrder, FALSE) <> ISNULL(PlanningStagesAreOld.StatusOrder,
	|		FALSE) AS IndicatorsHaveChanged,
	|	ISNULL(NewPlanningStages.FilterByResponsibleEmployee,
	|		FALSE) <> ISNULL(PlanningStagesAreOld.FilterByResponsibleEmployee, FALSE) AS ChangedSelections_
	|INTO StatusOfRecalculation
	|FROM
	|	NewPlanningStages AS NewPlanningStages
	|		FULL JOIN PlanningStagesAreOld AS PlanningStagesAreOld
	|		ON NewPlanningStages.PlanProfile = PlanningStagesAreOld.PlanProfile
	|		AND NewPlanningStages.PlanningStage = PlanningStagesAreOld.PlanningStage
	|		AND NewPlanningStages.PlanningPeriod = PlanningStagesAreOld.PlanningPeriod
	|		AND NewPlanningStages.RowPicture = PlanningStagesAreOld.RowPicture
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(StatusOfRecalculation.StructureHasChanged) AS StructureHasChanged,
	|	MAX(StatusOfRecalculation.IndicatorsHaveChanged) AS IndicatorsHaveChanged,
	|	MAX(StatusOfRecalculation.ChangedSelections_) AS ChangedSelections_
	|FROM
	|	StatusOfRecalculation AS StatusOfRecalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewPlanningStages.PlanProfile AS PlanProfile,
	|	NewPlanningStages.Presentation AS Presentation,
	|	NewPlanningStages.PlanningProcedure AS PlanningProcedure,
	|	NewPlanningStages.StagePlanningOrder AS StagePlanningOrder,
	|	NewPlanningStages.PlanningStage AS PlanningStage,
	|	NewPlanningStages.IsFolder AS IsFolder,
	|	NewPlanningStages.FillInByShortage AS FillInByShortage,
	|	NewPlanningStages.PlanningPeriod AS PlanningPeriod,
	|	NewPlanningStages.RowPicture AS RowPicture,
	|	NewPlanningStages.StatusOrder AS StatusOrder,
	|	NewPlanningStages.State AS State,
	|	NewPlanningStages.ColumnName AS ColumnName,
	|	NewPlanningStages.AccessRightUpdate AS AccessRightUpdate,
	|	NewPlanningStages.AccessRightRead AS AccessRightRead,
	|	NewPlanningStages.FilterByResponsibleEmployee AS FilterByResponsibleEmployee,
	|	NewPlanningStages.PlanProfile.PlanType AS PlanProfilePlanType,
	|	NewPlanningStages.PlanningStage.Description AS PlanningStageName,
	|	NewPlanningStages.PlanProfile.NumberOfPeriods AS PlanProfileQuantityOfPeriods,
	|	NewPlanningStages.PlanProfile.Description AS PlanProfileName
	|FROM
	|	NewPlanningStages AS NewPlanningStages
	|ORDER BY
	|	StagePlanningOrder,
	|	IsFolder DESC,
	|	PlanningProcedure,
	|	RowPicture,
	|	PlanningPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShortagesCalculationQueueInStages.Scenario AS Scenario,
	|	ShortagesCalculationQueueInStages.PlanProfile AS PlanProfile,
	|	ShortagesCalculationQueueInStages.PlanningPeriod AS PlanningPeriod
	|FROM
	|	InformationRegister.ShortagesCalculationQueueInStages AS ShortagesCalculationQueueInStages
	|WHERE
	|	ShortagesCalculationQueueInStages.Scenario = &Scenario
	|	AND ShortagesCalculationQueueInStages.PlanningPeriod BETWEEN &BeginOfPeriod AND &PeriodEnding";
	
	TablePeriods = FormAttributeToValue("TimeIntervals", Type("ValueTable"));
	Query.SetParameter("TablePeriods", TablePeriods);
	Query.SetParameter("PlanningStagesTable", PlanningStagesTable.Unload());
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
	Query.SetParameter("PeriodEnding", Object.PeriodEnding);
	
	Query.SetParameter("AccessRightChangePurchasePlan", AccessRightChangePurchasePlan);
	Query.SetParameter("AccessRightToReadThePurchasePlan", AccessRightToReadThePurchasePlan);
	Query.SetParameter("AccessRightChangeSalesPlan", AccessRightChangeSalesPlan);
	Query.SetParameter("AccessRightToReadTheSalesPlan", AccessRightToReadTheSalesPlan);
	Query.SetParameter("AccessRightsChangeTheSalesPlanByCategory", AccessRightsChangeTheSalesPlanByCategory);
	Query.SetParameter("AccessRightToReadTheSalesPlanByCategory", AccessRightToReadTheSalesPlanByCategory);
	Query.SetParameter("AccessRightChangeAssemblyDisassemblyPlan", AccessRightChangeAssemblyDisassemblyPlan);
	Query.SetParameter("ReadAccessRightAssemblyDisassemblyPlan", ReadAccessRightAssemblyDisassemblyPlan);
	Query.SetParameter("AccessRightChangeProductionPlan", AccessRightChangeProductionPlan);
	Query.SetParameter("AccessRightReadProductionPlan", AccessRightReadProductionPlan);
	Query.SetParameter("AccessRightChangeInternalConsumptionPlan", AccessRightChangeInternalConsumptionPlan);
	Query.SetParameter("AccessRightReadInternalConsumptionPlan", AccessRightReadInternalConsumptionPlan);
	Query.SetParameter("AccessRightChangeBalancePlan", AccessRightChangeBalancePlan);
	Query.SetParameter("AccessRightReadBalancePlan", AccessRightReadBalancePlan);
	
	Query.SetParameter("EmployeeResponsible", Object.EmployeeResponsible);
	Query.SetParameter("FilterEmployeeResponsible", ValueIsFilled(Object.EmployeeResponsible));
	
	SetPrivilegedMode(True);
	RequestPackage = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	StatusOfRecalculation = RequestPackage[8].Select();
	StatusOfRecalculation.Next();
	
	If StatusOfRecalculation.StructureHasChanged = Null Then
		Return False;
	EndIf;
	
	TableStagesOfPlanning = RequestPackage[10].Unload();
	If SetTheShortageRecalculationIndicator 
		Or TableStagesOfPlanning.Count() >0 Then
		SetTheShortageRecalculationIndicator = False;
		CurPageNew = Items.CalculatingPage; 
	Else
		CurPageNew = Items.PageIsCalculated;
	EndIf;
	
	If Items.CalculationOfShortagesInStages.CurrentPage<>CurPageNew Then
		Items.CalculationOfShortagesInStages.CurrentPage = CurPageNew;
	EndIf;
	
	If Not StatusOfRecalculation.StructureHasChanged 
		And Not StatusOfRecalculation.IndicatorsHaveChanged 
		And Not StatusOfRecalculation.ChangedSelections_ Then
		Return False;
	EndIf;
	
	If StatusOfRecalculation.IndicatorsHaveChanged Then
		ShortageRecalculationControlTimer = 0.5;
	EndIf;
	
	TableStagesOfPlanning = RequestPackage[9].Unload();
	PlanningStagesTable.Load(TableStagesOfPlanning);
	
	PlanningProcedure = Undefined;
	ProcedureForPlanningAdjustments = Undefined;
	ElementPlanningStage = PlanningStages;
	PlanViewElement_ = PlanningStages;
	
	If StatusOfRecalculation.StructureHasChanged Then
		PlanningStages.GetItems().Clear();
	EndIf;
	
	For Each String In TableStagesOfPlanning Do
		
		If String.IsFolder Then
			If PlanningProcedure <> String.PlanningProcedure Then
				If StatusOfRecalculation.StructureHasChanged Then
					ElementPlanningStage = PlanningStages.GetItems().Add();
					FillPropertyValues(ElementPlanningStage,String);
					PlanningProcedure = String.PlanningProcedure;
					If Not ValueIsFilled(String.PlanProfile) Then
						ElementPlanningStage.Presentation = NStr("vi = 'Cân đối kế hoạch';
																|ru = 'Баланс планов';
																|en = 'Plan balance'; fa = 'مانده برنامه';
																|it = 'Bilancio dei piani';
																|pl = 'Bilans planów';
																|tr = 'Plan bakiyesi'");
					EndIf;
				Else
					For Each PlanningStagesStage In PlanningStages.GetItems() Do
						If PlanningStagesStage.PlanProfile = String.PlanProfile Then
							ElementPlanningStage = PlanningStagesStage;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		
			ElementPlanningStage["State_" + String.ColumnName] = String.State;
			ElementPlanningStage["Status_" + String.ColumnName] = String.StatusOrder;
			ElementPlanningStage["FilterByResponsibleEmployee"] = String.FilterByResponsibleEmployee;
		Else
			If String.RowPicture = 4 Then
				
				If ProcedureForPlanningAdjustments <> String.PlanningProcedure Then
					
					If ValueIsFilled(String.PlanProfile) Then
						ParentElement = PlanViewElement_;
					Else 
						ParentElement = ElementPlanningStage;
					EndIf;
					
					If StatusOfRecalculation.StructureHasChanged Then
						PlanViewElementAdjustment = ParentElement.GetItems().Add();
						FillPropertyValues(PlanViewElementAdjustment,String);
						
					Else
						For Each PlanningStagesTypeOfPlan In ParentElement.GetItems() Do
							If PlanningStagesTypeOfPlan.PlanProfile = String.PlanProfile Then
								PlanViewElementAdjustment = PlanningStagesTypeOfPlan;
							EndIf;
						EndDo;
					EndIf;
					
					ProcedureForPlanningAdjustments = String.PlanningProcedure;
					
				EndIf;
				
				PlanViewElementAdjustment["State_" + String.ColumnName] = String.State;
				PlanViewElementAdjustment["Status_" + String.ColumnName] = String.StatusOrder;
				PlanViewElementAdjustment["FilterByResponsibleEmployee"] = String.FilterByResponsibleEmployee;
				Continue;
				
			EndIf;
			
			If PlanningProcedure <> String.PlanningProcedure Then
				If StatusOfRecalculation.StructureHasChanged Then
					PlanViewElement_ = ElementPlanningStage.GetItems().Add();
					FillPropertyValues(PlanViewElement_,String);
					PlanningProcedure = String.PlanningProcedure;
				Else
					For Each PlanningStagesTypeOfPlan In ElementPlanningStage.GetItems() Do
						If PlanningStagesTypeOfPlan.PlanProfile = String.PlanProfile Then
							PlanViewElement_ = PlanningStagesTypeOfPlan;
						EndIf;
					EndDo;
				EndIf;
			EndIf;
		
			PlanViewElement_["State_" + String.ColumnName] = String.State;
			PlanViewElement_["Status_" + String.ColumnName] = String.StatusOrder;
			PlanViewElement_["FilterByResponsibleEmployee"] = String.FilterByResponsibleEmployee;
		EndIf;
	EndDo;
	
	PlanningStagesTable.Load(TableStagesOfPlanning);
	UpdatePlanningAssistant();
	DeficitAnalysis();
	Return StatusOfRecalculation.StructureHasChanged
	
EndFunction

&AtClient
Procedure UpdateStageTree()
	
	If Not ValueIsFilled(Object.Scenario)
		Or Items.PlanningStages.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	PreviousActivePlanView = PlanningStages.FindByID(Items.PlanningStages.CurrentRow).PlanProfile;
	
	StructureHasChanged = UpdateStageTreeOnServer();
	RunningBackgroundJobSchedulingAssistant();
	If StructureHasChanged Then
		For Each TreeRow In PlanningStages.GetItems() Do
			Items.PlanningStages.Expand(TreeRow.GetID(), True);
		EndDo;
		
		AttachIdleHandler(
			"Attachable_ActivatePreviousPlanProfile",
			0.1,
			True);
	ElsIf Items.ProductDetails_5.Visible Then
		Items.ProductDetails_5.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ActivatePreviousPlanProfile()
	
	PlanningStagesElements = PlanningStages.GetItems();
	For Each PlanningStagesElement In PlanningStagesElements Do
		PlanViewElements = PlanningStagesElement.GetItems();
		For Each PlanViewElement In PlanViewElements Do
			If PlanViewElement.PlanProfile = PreviousActivePlanView Then
				CurRowId_ = PlanViewElement.GetID();
				Items.PlanningStages.CurrentRow = CurRowId_;
				Return;
			EndIf;
		EndDo;
		If PlanningStagesElement.PlanProfile = PreviousActivePlanView Then
			CurRowId_ = PlanningStagesElement.GetID();
			Items.PlanningStages.CurrentRow = CurRowId_;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure DisplayDetails_(PlanProfile, PlanningPeriod, ConsiderOpeningBalance, ThisIsAdjustment)
	
	ProductDetails_5.Parameters.SetParameterValue("Scenario",Object.Scenario);
	ProductDetails_5.Parameters.SetParameterValue("PlanningPeriod",PlanningPeriod);
	ProductDetails_5.Parameters.SetParameterValue("PlanProfile",PlanProfile);
	ProductDetails_5.Parameters.SetParameterValue("ConsiderOpeningBalance",ConsiderOpeningBalance);
	ProductDetails_5.Parameters.SetParameterValue("DemandAdjustment",ThisIsAdjustment);
	
	RevisionsOfPlanType = Common.ObjectAttributesValues(PlanProfile, "PlanningOfGoodsStock,PlanType,DemandPlanning,Parent,FillInByShortage,IsFolder");
	ParentNeedsPlanning = False;
	If ValueIsFilled(RevisionsOfPlanType.Parent) Then
		ParentNeedsPlanning = Common.ObjectAttributeValue(RevisionsOfPlanType.Parent, "DemandPlanning");
	EndIf;
	
	Items.ProductDetails_5OpeningBalance.Visible = PlanProfile = Catalogs.PlanProfiles.EmptyRef()
												Or RevisionsOfPlanType.PlanningOfGoodsStock
												Or	RevisionsOfPlanType.PlanType = Enums.TypesOfPlans.PlanOfGoodsStock;
											
	Items.ProductDetails_5Receipt.Visible = PlanProfile = Catalogs.PlanProfiles.EmptyRef()
													Or Not RevisionsOfPlanType.DemandPlanning
													And Not ParentNeedsPlanning
													And Not ThisIsAdjustment
													And RevisionsOfPlanType.PlanType <> Enums.TypesOfPlans.PlanOfGoodsStock
													And Not RevisionsOfPlanType.PlanningOfGoodsStock;
													
	Items.ProductDetails_5Expense.Visible = PlanProfile = Catalogs.PlanProfiles.EmptyRef()
													Or RevisionsOfPlanType.DemandPlanning
													Or ParentNeedsPlanning;
													
	Items.ProductDetails_5ExpenseAdjustment.Visible = PlanProfile <> Catalogs.PlanProfiles.EmptyRef()
														And Not ParentNeedsPlanning
														And Not RevisionsOfPlanType.DemandPlanning
														And RevisionsOfPlanType.PlanType <> Enums.TypesOfPlans.PlanOfGoodsStock
														And Not RevisionsOfPlanType.PlanningOfGoodsStock;
												
	Items.ProductDetails_5Demand.Visible = PlanProfile <> Catalogs.PlanProfiles.EmptyRef() And ((RevisionsOfPlanType.FillInByShortage <> Null And RevisionsOfPlanType.FillInByShortage) 
													Or (RevisionsOfPlanType.IsFolder And Not RevisionsOfPlanType.DemandPlanning And Not RevisionsOfPlanType.PlanningOfGoodsStock));
	
	Items.ProductDetails_5ToChange.Visible = PlanProfile <> Catalogs.PlanProfiles.EmptyRef() And ((RevisionsOfPlanType.FillInByShortage <> Null And RevisionsOfPlanType.FillInByShortage) 
													Or (RevisionsOfPlanType.IsFolder And Not RevisionsOfPlanType.DemandPlanning And Not RevisionsOfPlanType.PlanningOfGoodsStock));
	
	Items.ProductDetails_5ClosingBalance.Visible = PlanProfile = Catalogs.PlanProfiles.EmptyRef();
	
EndProcedure

#Region BackgroundJobs

&AtClient
Procedure RunBackgroundJob1(JobName, ProcedureParameters)
	
	ClearMessages();
	
	RunResult = RunBackgroundJobOnServer(
		JobName,
		ProcedureParameters);
	
	If RunResult.StartWaiting Then
		
		TimeConsumingOperationsClient.WaitCompletion(
			TimeConsumingOperation,
			New CallbackDescription("ExecuteInBackgroundCompletion", ThisObject, New Structure("JobName", JobName)),
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
		
	Else
		
		ShortageRecalculationControlTimer = 0.5;
		RecalculateStagesAndIndicators();
		
	EndIf;
	
EndProcedure

&AtServer
Function RunBackgroundJobOnServer(JobName, ProcedureParameters)
	
	If JobName = "RunTheRecalculationOfShortagesInStagesForAllThePeriods" Then
		JobDescription = NStr("vi = 'Bắt đầu tính toán lại thiếu hụt theo các giai đoạn cho tất cả các kỳ';
								|ru = 'Запустить пересчет дефицитов по этапам по всем периодам';
								|en = 'Run the recalculation of shortages in stages for all the periods'; fa = 'اجرای محاسبه مجدد کسری‌ها در مراحل برای همه دوره‌ها';
								|it = 'Avviare il ricalcolo dei deficit per le fasi per tutti i periodi';
								|pl = 'Uruchom przeliczanie niedoborów według etapów dla wszystkich okresów';
								|tr = 'Tüm dönemler için aşama açıklarının yeniden hesaplanmasını başlat'");
		ProcedureName = "DataProcessors.PlanningProcessManagement.RunTheRecalculationOfShortagesInStagesForAllThePeriods";
	ElsIf JobName = "FillPlansByShortagesInAllPeriods" Then
		JobDescription = NStr("vi = 'Điền vào các kế hoạch thiếu hụt cho tất cả các giai đoạn';
								|ru = 'Заполнить планы по дефицитам во всех периодах';
								|en = 'Fill plans by shortages in all periods'; fa = 'Fill plans by shortages in all periods';
								|it = 'Compilare i piani per deficit in tutti i periodi';
								|pl = 'Wypełnij plany według niedoborów we wszystkich okresach';
								|tr = 'Mali açığa göre planları tüm dönemlerde doldur'");
		ProcedureName = "DataProcessors.PlanningProcessManagement.FillInDeficitPlansByPeriod";
	ElsIf JobName = "FillPlansByShortagesBeforeColumn" Then
		JobDescription = NStr("vi = 'Điền vào các kế hoạch thiếu hụt';
								|ru = 'Заполнить планы по дефицитам';
								|en = 'Fill in plans by shortages'; fa = 'Fill in plans by shortages';
								|it = 'Compilare i piani per deficit';
								|pl = 'Wypełnij plany według niedoborów';
								|tr = 'Mali açığa göre planları doldur'");
		ProcedureName = "DataProcessors.PlanningProcessManagement.FillInDeficitPlansByPeriod";
	ElsIf JobName = "RecalculationPlanningAssistant" Then
		JobDescription = NStr("vi = 'Trợ giúp lập kế hoạch thanh toán bù trừ toàn cầu';
								|ru = 'Глобальный перерасчет помощник планирования';
								|en = 'Global recalculation planning wizard'; fa = 'Global recalculation planning wizard';
								|it = 'Ricalcolo globale assistente di pianificazione';
								|pl = 'Globalne przeliczenie pomocnik planowania';
								|tr = 'Planlama sihirbazının küresel olarak yeniden hesaplanması'");
		ProcedureName = "DataProcessors.PlanningProcessManagement.RecalculationPlanningAssistant";
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.RunInBackground = True;
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, ProcedureParameters, ExecutionParameters);
	
	StartWaiting = True;
	
	If TimeConsumingOperation.Status <> "Running" Then
		
		StartWaiting = False;
		TimeConsumingOperation = Undefined;
		
	EndIf;
	
	Return New Structure("StartWaiting", StartWaiting);
	
EndFunction

&AtClient
Procedure ExecuteInBackgroundCompletion(Result, AddlParameters) Export
	
	TimeConsumingOperation = Undefined;
	
	If Result <> Undefined Then
		
		ShortageRecalculationControlTimer = 0.5;
		RecalculateStagesAndIndicators();
	
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
#Region PlanningWizard

&AtClient
Procedure RunningBackgroundJobSchedulingAssistant()
	
	If EnableFillingByShortagesPlanningWizard And NewBackgroundJob Then 
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("Scenario",Object.Scenario);
		ProcedureParameters.Insert("PlanProfile",RecalculationElement[0].PlanProfile);
		ProcedureParameters.Insert("BeginOfPeriod",RecalculationElement[0].StartPeriod);
		ProcedureParameters.Insert("PeriodEnding",RecalculationElement[0].EndPeriod_);
		NewBackgroundJob = False;
		RunBackgroundJob1("RecalculationPlanningAssistant",
		ProcedureParameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure DeficitAnalysis()
	
	FirstPlan = FindingFirstDeficitPlan();
	
	If FirstPlan = Undefined Then
		EnableFillingByShortagesPlanningWizard = False;
		Return;
	EndIf;
	
	If EnableFillingByShortagesPlanningWizard Then
		If RecalculationElement.Count() > 0 Then
			If (RecalculationElement[0].PlanProfile = FirstPlan.PlanProfile
				And RecalculationElement[0].StartPeriod = FirstPlan.StartPeriod
				And RecalculationElement[0].EndPeriod_ = FirstPlan.EndPeriod_)
				Then
				Return;
			Else 
				RecalculationElement.Clear();
				NewRow = RecalculationElement.Add();
				NewRow.PlanProfile = FirstPlan.PlanProfile;
				NewRow.StartPeriod = FirstPlan.StartPeriod;
				NewRow.EndPeriod_ = FirstPlan.EndPeriod_;
				NewRow.StatusOrder = FirstPlan.StatusOrder;
				NewRow.NumberInTable = FirstPlan.NumberInTable;
				NewRow.State = FirstPlan.State;
				NewRow.FillingByShortages = FirstPlan.FillingByShortages;
				NewRow.PlanningStage = FirstPlan.PlanningStage;
				NewRow.Name = FirstPlan.Name;
				NewRow.PeriodInTable = FirstPlan.PeriodInTable;
				NewBackgroundJob = True;	
			EndIf;
		Else
			RecalculationElement.Clear();
			NewRow = RecalculationElement.Add();
			NewRow.PlanProfile = FirstPlan.PlanProfile;
			NewRow.StartPeriod = FirstPlan.StartPeriod;
			NewRow.EndPeriod_ = FirstPlan.EndPeriod_;
			NewRow.StatusOrder = FirstPlan.StatusOrder;
			NewRow.NumberInTable = FirstPlan.NumberInTable;
			NewRow.State = FirstPlan.State;
			NewRow.FillingByShortages = FirstPlan.FillingByShortages;
			NewRow.PlanningStage = FirstPlan.PlanningStage;
			NewRow.Name = FirstPlan.Name;
			NewRow.PeriodInTable = FirstPlan.PeriodInTable;
			NewBackgroundJob = True;
		EndIf;
	Else 
		Return;
	EndIf;
	
EndProcedure

&AtServer
Function FindingFirstDeficitPlan()
	
	For Each Plan In TableOfPlanningWizardItemsCurrentPeriod Do 
		If Plan.FillingByShortages And Plan.State = 1 Then 
			Return Plan;	
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure UpdatePlanningAssistant()
	Items.HidePlanningWizard.Visible = True;
	ClearingPlanningAssistantArea();
	PlanningWizardItemsTable.Clear();
	CreateAssistant();
	
	
EndProcedure

&AtServer
Procedure ClearingPlanningAssistantArea()
	
	TableOfPlanningWizardItemsCurrentPeriod.Clear();
	PlanningAssistantTableImportantGroups = Items.PlanningWizard;
	DeleteList = New Array;
	
	For Each Item In PlanningAssistantTableImportantGroups.ChildItems Do 
		DeleteList.Add(Item);
	EndDo;
	
	QuantityOfAle = DeleteList.Count();
	
	For Counter = 0 To (QuantityOfAle-1) Do
		Items.Delete(DeleteList[Counter]);
	EndDo;
	
	
EndProcedure

&AtServer
Procedure CreateAssistant()
	
	NumberOfItemsInWizard = 0;
	PlanCounter = 0;
	CreateTableOfElementsOfPlanningAssistantCurPeriod();
	CreateGraphicalInterface();
	CreateCorrectionData();
	FillByServerDeficits();
	CheckForPlanningAssistantElements();
	
EndProcedure

&AtServer
Procedure CreateTableOfElementsOfPlanningAssistantCurPeriod()
	
	CurStartDateOfPeriod = PlanningClientServer.CalculateStartDateOfPeriod(CurrentSessionDate(),Object.Periodicity);
	PlanningStageFound    = False;
	CurrentGroupProcessing = False;
	PlanningType = Undefined;
	ViewOfActualPlan = Undefined;
	ListOfCurrentPlans = 0;
	FillingByShortageProblems = False;
	RelevantDataProblems = False;
	For Each Plan In PlanningStagesTable Do
		
		If Plan.PlanProfilePlanType = Enums.TypesOfPlans.PlanOfGoodsStock 
			And Not Plan.IsFolder
			And Plan.PlanningPeriod = CurStartDateOfPeriod  Then
			If Not CheckingAccessRightsPlanningAssistant(Plan.PlanProfilePlanType)Then 	
				Continue;
			EndIf;
			If Plan.StatusOrder = 9 Then
				RelevantDataProblems = True;
			EndIf;
			NewItem = TableOfPlanningWizardItemsCurrentPeriod.Add();
			FillPropertyValues(NewItem, Plan);
			NewItem.StartPeriod = Plan.PlanningPeriod;
			NewItem.EndPeriod_  = PlanningClientServer.CalculatePeriodEndDate(Plan.PlanningPeriod,Object.Periodicity);
			NewItem.FillingByShortages = False;
			NewItem.TypeOfPlan = "Balance";
		EndIf;
		
		If Plan.IsFolder And PlanningType <> Plan.PlanProfile Then
			CurrentGroupProcessing = False;
		EndIf;
		
		If CurrentGroupProcessing And Not(Plan.FillInByShortage) 
			And Not(Plan.IsFolder)
			And Plan.PlanningPeriod >= CurStartDateOfPeriod Then
			If Not CheckingAccessRightsPlanningAssistant(Plan.PlanProfilePlanType) Then 	
				Continue;
			EndIf;
			If Plan.StatusOrder = 9 Then
				RelevantDataProblems = True;
			EndIf;
			If Plan.PlanProfile <> ViewOfActualPlan Then
				ViewOfActualPlan   = Plan.PlanProfile;
				ListOfCurrentPlans = 0;
			EndIf;
			If ListOfCurrentPlans >= Plan.PlanProfileQuantityOfPeriods Then
				Continue;
			EndIf;
			ListOfCurrentPlans = ListOfCurrentPlans + 1;
			NewItem = TableOfPlanningWizardItemsCurrentPeriod.Add();
			FillPropertyValues(NewItem, Plan);
			NewItem.StartPeriod = Plan.PlanningPeriod;
			NewItem.EndPeriod_  = PlanningClientServer.CalculatePeriodEndDate(Plan.PlanningPeriod,Object.Periodicity);
			NewItem.TypeOfPlan    = "Initial_";
		EndIf;
		
		If Plan.IsFolder
			And Not PlanningStageFound Then
			ResidueGroup = Common.ObjectAttributeValue(Plan.PlanningStage, "PlanningOfGoodsStock");
			If Not ResidueGroup = Undefined Then
				If  Not ResidueGroup Then
					PlanningType = Plan.PlanProfile;
					PlanningStageFound    = True;
					CurrentGroupProcessing = True;
				EndIf;
			EndIf;
		EndIf;
		
		If Not(Plan.IsFolder) 
			And Plan.FillInByShortage Then
			If Not CheckingAccessRightsPlanningAssistant(Plan.PlanProfilePlanType) Then 	
				Continue;
			EndIf;
			If Plan.State = 1 Then
				FillingByShortageProblems = True;
			EndIf;
			NewItem = TableOfPlanningWizardItemsCurrentPeriod.Add();
			FillPropertyValues(NewItem, Plan);
			NewItem.StartPeriod = Plan.PlanningPeriod;
			NewItem.EndPeriod_ = PlanningClientServer.CalculatePeriodEndDate(Plan.PlanningPeriod,Object.Periodicity);
			NewItem.FillingByShortages = True;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CheckForPlanningAssistantElements()
	
	For Each HelperElement In Items.PlanningWizard.ChildItems Do
		If HelperElement.ChildItems[1].ChildItems.Count() > 0 Then
			Return;
		EndIf;
	EndDo;
	Items.HidePlanningWizard.Visible = False;
	
EndProcedure

&AtServer
Procedure CreateCorrectionData()
	
	AdjustmentGroup = CreateAssistantGroup("CheckAdjustments");
	AdjustmentGroup.Visible = False;
	CreateCaption(AdjustmentGroup,False,NStr("vi = 'Kiểm tra điều chỉnh';
											|ru = 'Проверить корректировки';
											|en = 'Check adjustments'; fa = 'Check adjustments';
											|it = 'Controllare le rettifiche';
											|pl = 'Sprawdź korekty';
											|tr = 'Düzeltmelere göz at'"),"Adjusting");
	CrHelperBody = CreateHelperBody(AdjustmentGroup,True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	AdjustmentOfPlannedDemand.Status AS Status,
	|	AdjustmentOfPlannedDemand.Ref AS Ref,
	|	AdjustmentOfPlannedDemand.Presentation AS Presentation,
	|	AdjustmentOfPlannedDemand.Period AS Period,
	|	AdjustmentOfPlannedDemand.PlanProfile AS PlanProfile,
	|	AdjustmentOfPlannedDemand.PlanProfile.Description AS PlanProfileName
	|FROM
	|	Document.AdjustmentOfPlannedDemand AS AdjustmentOfPlannedDemand
	|WHERE
	|	AdjustmentOfPlannedDemand.Scenario = &Scenario
	|	AND AdjustmentOfPlannedDemand.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND AdjustmentOfPlannedDemand.Status = &Status
	|	AND AdjustmentOfPlannedDemand.Posted = TRUE";
	
	Query.SetParameter("Scenario", Object.Scenario);
	Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Object.PeriodEnding);
	Query.SetParameter("Status", Enums.StatusesOfPlanAdjustments.ForChecking);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Unload();                  
	
	NewArray = New Array;
	For Each Plan In SelectionDetailRecords Do  
		NewRow = TableOfAdjustments.Add();
		NewRow.Name = "HelperElement"+String(NumberOfItemsInWizard);
		NewRow.Document = Plan.Ref;
		ItemTitle=NStr("vi = 'Hiệu chỉnh';
						|ru = 'Скорректировать';
						|en = 'Adjust'; fa = 'تعدیل';
						|it = 'Rettificare';
						|pl = 'Skoryguj';
						|tr = 'Düzelt'");
		
		
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("ActionType",ItemTitle);
		ProcedureParameters.Insert("DocumentType", Plan.Presentation);
		ProcedureParameters.Insert("PlanProfile",Plan.PlanProfileName);
		ProcedureParameters.Insert("StartPeriod", Plan.Period);
		
		CreateHelperElements(ProcedureParameters,
		CrHelperBody,
		"",
		True);
		AdjustmentGroup.Visible = True;
		CreatingGraphicDesign = True;
	EndDo;
	
EndProcedure

&AtServer
Procedure PlanningAssistantShowInTable(PlanProfile,Date)
	
	PlanningStagesElements = PlanningStages.GetItems();
	
	For Each PlanningStagesElement In PlanningStagesElements Do
		PlanViewElements = PlanningStagesElement.GetItems();
		For Each PlanViewElement In PlanViewElements Do
			If PlanViewElement.PlanProfile = PlanProfile Then
				CurRowId_ = PlanViewElement.GetID();
				Items.PlanningStages.CurrentRow = CurRowId_;
				Break;
			EndIf;
		EndDo;
		If PlanningStagesElement.PlanProfile = PlanProfile Then
			CurRowId_ = PlanningStagesElement.GetID();
			Items.PlanningStages.CurrentRow = CurRowId_;
		EndIf;
	EndDo;
	
	FilterParameter = New Structure("Date",Date);
	Selection = PlanningWizardPeriodCounter.FindRows(FilterParameter);
	If Selection.Count() = 0 Then
		Return;	
	EndIf;
	Items.PlanningStages.CurrentItem =  Items.PlanningStages.ChildItems[Selection[0].Counter];
	
EndProcedure

&AtServer
Procedure CreateGraphicalInterface()
	
	UpdateSourceData = CreateAssistantGroup("UpdateInitialData");
	CreateCaption(UpdateSourceData,
	Not RelevantDataProblems,
	NStr("vi = 'Cập nhật dữ liệu nguồn';
		|ru = 'Актуализировать исходные данные';
		|en = 'Update initial data'; fa = 'Update initial data';
		|it = 'Aggiornare i dati sorgente';
		|pl = 'Zaktualizuj pochodne dane';
		|tr = 'İlk verileri güncelle'"));
	
	HelperBodyAct = CreateHelperBody(UpdateSourceData,RelevantDataProblems);
	UpdateSourceData.Visible = RelevantDataProblems;
	
	
	RecalculateByDeficitsGroup = CreateAssistantGroup("RecalculateByShortages");
	CreateCaption(RecalculateByDeficitsGroup,
	Not FillingByShortageProblems,
	NStr("vi = 'Tính toán lại cho thâm hụt';
		|ru = 'Перерасчитать по дефицитам';
		|en = 'Recalculate by shortages'; fa = 'Recalculate by shortages';
		|it = 'Ricalcolare per deficit';
		|pl = 'Przelicz wg niedoborów';
		|tr = 'Mali açığa göre yeniden hesapla'"),
	"Deficit");
	DFHelperBody = CreateHelperBody(RecalculateByDeficitsGroup,FillingByShortageProblems);
	RecalculateByDeficitsGroup.Visible = FillingByShortageProblems;
	
	
	HintAdded        = False;
	HintAddedOriginalPlans  = False;
	HintAddedDeficits       = False;
	
	For Each Item In TableOfPlanningWizardItemsCurrentPeriod Do
		If Not Item.FillingByShortages Then
			ItemTitle = Undefined;
			If Item.StatusOrder = 9 Then 
				ItemTitle=NStr("vi = 'Tạo mới';
								|ru = 'Создать';
								|en = 'Create'; fa = 'ایجاد';
								|it = 'Creare';
								|pl = 'Utwórz';
								|tr = 'Oluştur'");
			EndIf;
			If  ItemTitle <> Undefined Then
				If Item.FillingByShortages Then
					ProcedureParameters = New Structure;
					ProcedureParameters.Insert("ActionType",ItemTitle);
					ProcedureParameters.Insert("DocumentType", Item.PlanProfileName);
					ProcedureParameters.Insert("PlanProfile", Item.PlanningStageName);
					ProcedureParameters.Insert("StartPeriod", Item.StartPeriod);
					CreateHelperElements(ProcedureParameters,DFHelperBody,Item);
				Else
					If  Item.TypeOfPlan = "Balance" Then
						If Not HintAdded Then
							NewItem = Items.Add("LeftoversUnderHeading",Type("FormDecoration"),HelperBodyAct);
							NewItem.Title = New FormattedString(NStr("vi = 'Để thay đổi kế hoạch từ thời điểm hiện tại, hãy thiết lập kế hoạch cân bằng:';
																	|ru = 'Для измения планов с текущего момента заведите планы остатков:';
																	|en = 'Create goods stock plans to change the plans from current moment:'; fa = 'Create goods stock plans to change the plans from current moment:';
																	|it = 'Per modificare i piani da questo momento  impostate i piani di giacenze:';
																	|pl = 'Dla zmiany planów z bieżącego momentu wprowadź plany pozostałości:';
																	|tr = 'Şu anki planların değiştirilmeleri için mal stok planları başlatın:'"),,StyleColors.NoteText);
							HintAdded = True;
						EndIf;
						
					EndIf;
					If  Item.TypeOfPlan = "Initial_" Then
						If  Not HintAddedOriginalPlans Then
							NewItem = Items.Add("SourceDataUnderHeading",Type("FormDecoration"),HelperBodyAct);
							NewItem.Title = New FormattedString(NStr("vi = 'Để lập kế hoạch cho các giai đoạn sau, hoàn thành các kế hoạch:';
																	|ru = 'Для планирования на следующие периоды заполните планы:';
																	|en = 'Fill in plans to plan for the following periods:'; fa = 'Fill in plans to plan for the following periods:';
																	|it = 'Per pianificare per i periodi successivi compilate i piani:';
																	|pl = 'W celu planowania na następujące okresy wypełnij plany:';
																	|tr = 'Mevcut plan doldurma dönemlerinde planlama için:'"),,StyleColors.NoteText);
							HintAddedOriginalPlans = True;
						EndIf;
					EndIf;
					ProcedureParameters = New Structure;
					ProcedureParameters.Insert("ActionType",ItemTitle);
					ProcedureParameters.Insert("DocumentType", Item.PlanProfileName);
					ProcedureParameters.Insert("PlanProfile", Item.PlanningStageName);
					ProcedureParameters.Insert("StartPeriod", Item.StartPeriod);
					CreateHelperElements(ProcedureParameters,HelperBodyAct,Item);
				EndIf;
			EndIf;
		Else
			If  Item.State = 1 Then
				If Not HintAddedDeficits Then
					RecalculationButton = Items.Add("RecalculateAllPlans", Type("FormButton"),DFHelperBody);
					RecalculationButton.Title = NStr("vi = 'Tính toán lại tất cả các kế hoạch cho thâm hụt';
													|ru = 'Перерасчитать по дефицитам все планы';
													|en = 'Recalculate all plans by shortages'; fa = 'Recalculate all plans by shortages';
													|it = 'Ricalcolare per deficit tutti i piani';
													|pl = 'Przelicz wg niedoborów wszystkie plany';
													|tr = 'Mali açığa göre tüm planları yeniden hesapla'");
					RecalculationButton.Type = FormButtonType.CommandBarButton;
					RecalculationButton.CommandName = "FillingShortages"; 
					HintAddedDeficits = True;
				EndIf;
				ItemTitle=NStr("vi = 'Tính toán lại';
								|ru = 'Перерасчитать';
								|en = 'Recalculate'; fa = 'محاسبه مجدد';
								|it = 'Ricalcolare';
								|pl = 'Przelicz';
								|tr = 'Yeniden hesapla'");
				ProcedureParameters = New Structure;
				ProcedureParameters.Insert("ActionType",ItemTitle);
				ProcedureParameters.Insert("DocumentType", Item.PlanProfileName);
				ProcedureParameters.Insert("PlanProfile", Item.PlanningStageName);
				ProcedureParameters.Insert("StartPeriod", Item.StartPeriod);
				CreateHelperElements(ProcedureParameters,DFHelperBody,Item);
			EndIf;
		EndIf;	
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateHelperElements(ProcedureParameters,Var_Group,RowColumn ,Adjusting = False )//Type Of Action - Create,Recalculate
	ActionType = ProcedureParameters.ActionType;
	DocumentType = ProcedureParameters.DocumentType;
	PlanProfile = ProcedureParameters.PlanProfile;
	Date = ProcedureParameters.StartPeriod;
	
	AssistantGroup =Items.Add("UnderPlanningAssistantGroup"+String(NumberOfItemsInWizard), Type("FormGroup"),Var_Group);
	AssistantGroup.Type = FormGroupType.UsualGroup;
	AssistantGroup.Representation = UsualGroupRepresentation.None;
	AssistantGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	AssistantGroup.ShowTitle = False;
	HeaderParts = New Array;
	DeterminingNumberOfPlanningPeriods();
	HeaderParts.Add(New FormattedString(String(NumberOfItemsInWizard+1)+") ",,,,));
	HeaderParts.Add(New FormattedString(ActionType + " ",,StyleColors.HyperlinkColor,,ActionType));        ////|||||\\\\
	HeaderParts.Add(New FormattedString(DocumentType + ?(PlanProfile = "",""," " + NStr("vi = 'đến';
																						|ru = 'по';
																						|en = 'to'; fa = 'تا';
																						|it = 'al';
																						|pl = 'to';
																						|tr = 'göre'"))+" ",,,));
	HeaderParts.Add(New FormattedString(PlanProfile + " " + NStr("vi = 'đến';
																|ru = 'по';
																|en = 'to'; fa = 'تا';
																|it = 'al';
																|pl = 'to';
																|tr = 'göre'") + " ",,,,));
	If Common.ObjectAttributeValue(Object.Scenario, "ShowNumberOfPeriod") Then
		TablePeriods = ThisForm.TimeIntervals; // See Planning.TablePeriods
		Rows = TablePeriods.FindRows(New Structure("StartDate",Date));
		If Rows.Count() > 0 Then
			HeaderParts.Add(New FormattedString(Rows[0].Title+" ",,,,));
		EndIf;
	Else
		HeaderParts.Add(New FormattedString(Format(Date,"DLF=DD")+" ",,,,));
	EndIf;
	 
	Item = Items.Add("HelperElement"+String(NumberOfItemsInWizard), Type("FormDecoration"), AssistantGroup);
	Item.Title = New FormattedString(HeaderParts);
	
	If Not Adjusting  Then
		Item.SetAction("URLProcessing", "Attachable_ProcessHyperlinkClick");
		RowColumn.Name = Item.Name;		
		Item = Items.Add("ElementaryPicture"+String(NumberOfItemsInWizard), Type("FormDecoration"), AssistantGroup);
		Item.Title = New FormattedString(PictureLib.ShowInList,,,,"SetAsActive");
		Item.ToolTip = NStr("vi = 'Hiển thị trong danh sách';
							|ru = 'Показать в списке';
							|en = 'Show in list'; fa = 'نمایش در فهرست';
							|it = 'Visualizza nell''elenco';
							|pl = 'Pokaż na liście';
							|tr = 'Listede göster'");
		
	EndIf;
	Item.SetAction("URLProcessing", "Attachable_ProcessHyperlinkClick");
	NumberOfItemsInWizard = NumberOfItemsInWizard + 1;
	
EndProcedure


&AtServer
Procedure DeterminingNumberOfPlanningPeriods()
	
	Counter = 1;
	PlanningWizardPeriodCounter.Clear();
	PlanProfile = PlanningStagesTable[0].PlanProfile;
	
	For Each Plan In PlanningStagesTable Do 
		If Plan.IsFolder Then
			If PlanProfile <> Plan.PlanProfile Then 
				Return;
			EndIf;
			NewRow = PlanningWizardPeriodCounter.Add();
			NewRow.Counter = Counter;
			NewRow.Date = Plan.PlanningPeriod;
			Counter = Counter + 1;
		Else 
			Return;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function CreateAssistantGroup(Name1, Parent = Undefined)
	
	If Parent = Undefined Then
		Parent = Items.PlanningWizard;
	EndIf;
	
	Var_Group = Items.Add(Name1, Type("FormGroup"), Parent);
	Var_Group.Type = FormGroupType.UsualGroup;
	Var_Group.Representation = UsualGroupRepresentation.None;
	Var_Group.Group = ChildFormItemsGroup.Vertical;
	Var_Group.ShowTitle = False;	
	
	Return Var_Group;
	
EndFunction

&AtServer
Function CheckingAccessRightsPlanningAssistant(PlanType)
	
	If PlanType = Enums.TypesOfPlans.PurchasePlan Then
		If Not AccessRightChangePurchasePlan Then
			Return False;	
		EndIf;
		If Not AccessRightToReadThePurchasePlan Then
			Return False;	
		EndIf;
	EndIf;
	
	If  PlanType = Enums.TypesOfPlans.SalesPlanByCategories Then
		If Not AccessRightsChangeTheSalesPlanByCategory Then
			Return False;	
		EndIf;
		If Not AccessRightToReadTheSalesPlanByCategory Then
			Return False;	
		EndIf;
	EndIf;
	
	If  PlanType = Enums.TypesOfPlans.SalesPlan Then
		If Not AccessRightChangeSalesPlan Then
			Return False;	
		EndIf;
		If Not AccessRightToReadTheSalesPlan Then
			Return False;	
		EndIf;
	EndIf;
	
	If  PlanType = Enums.TypesOfPlans.AssemblyDisassemblyPlan Then
		If Not AccessRightChangeAssemblyDisassemblyPlan Then
			Return False;	
		EndIf;
		If Not ReadAccessRightAssemblyDisassemblyPlan Then
			Return False;	
		EndIf;
	EndIf;
	If  PlanType = Enums.TypesOfPlans.ProductionPlan Then
		If Not AccessRightChangeProductionPlan Then
			Return False;	
		EndIf;
		If Not AccessRightReadProductionPlan Then
			Return False;	
		EndIf;
	EndIf;
	If  PlanType = Enums.TypesOfPlans.PlanOfGoodsStock Then
		If Not AccessRightChangeBalancePlan Then
			Return False;	
		EndIf;
		If Not AccessRightReadBalancePlan Then
			Return False;	
		EndIf;
	EndIf;
	
	If  PlanType = Enums.TypesOfPlans.InventoryConsumptionPlan Then
		If Not AccessRightChangeInternalConsumptionPlan Then
			Return False;	
		EndIf;
		If Not AccessRightReadInternalConsumptionPlan Then
			Return False;	
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function CreateHelperBody(Var_Group,Visible = False)
	
	HelperSBody =Items.Add("HelperSBody"+Var_Group.Name,Type("FormGroup"),Var_Group);
	HelperSBody.Type = FormGroupType.UsualGroup;
	HelperSBody.Representation = UsualGroupRepresentation.StrongSeparation;
	HelperSBody.Group = ChildFormItemsGroup.Vertical;
	HelperSBody.Visible = Visible;
	HelperSBody.ShowTitle = False;
	
	Return HelperSBody;
	
EndFunction


// Parameters:
// 	Item - FormDecoration -
// 	FormattedStringURL - String
// 	StandardProcessing - Boolean
&AtClient
Procedure Attachable_ProcessHyperlinkClick(Item, FormattedStringURL, StandardProcessing)
	// 
	StandardProcessing = False;
	
	Name = StrReplace(Item.Name,"ElementaryPicture","HelperElement"); 
	FilterParameter = New Structure("Name",Name);
	DesiredElement_ = TableOfPlanningWizardItemsCurrentPeriod.FindRows(FilterParameter);
	
	If FormattedStringURL= "Create" Then
		Name = StrReplace(Item.Name,"HelperElement","ElementaryPicture");
		PlanningAssistantShowInTable(DesiredElement_[0].PlanProfile,DesiredElement_[0].StartPeriod);
		ListOfPlanProfiles = GetListOfPlanTypesToSelect(Items.PlanningStages.CurrentRow);
		FormParameters = New Structure;
		FormParameters.Insert("Scenario",Object.Scenario);
		FormParameters.Insert("PlanProfile",DesiredElement_[0].PlanProfile);
		FormParameters.Insert("ListOfPlanProfiles",ListOfPlanProfiles);
		FormParameters.Insert("Products",Undefined);
		FormParameters.Insert("Characteristic",Undefined);
		FormParameters.Insert("Purpose",Undefined);
		FormParameters.Insert("BeginOfPeriod",DesiredElement_[0].StartPeriod);
		FormParameters.Insert("PeriodEnding",DesiredElement_[0].EndPeriod_);
		FormParameters.Insert("DataType","");
		OpenForm("DataProcessor.PlanningProcessManagement.Form.FormOfDocuments", FormParameters, ThisForm);
	ElsIf   FormattedStringURL ="Recalculate_" Then
		If EnableFillingByShortagesPlanningWizard Then
			Return;
		EndIf;
		ProcedureParameters = New Structure;
		ProcedureParameters.Insert("Scenario",Object.Scenario);
		ProcedureParameters.Insert("PlanProfile",DesiredElement_[0].PlanProfile);
		ProcedureParameters.Insert("BeginOfPeriod",DesiredElement_[0].StartPeriod);
		ProcedureParameters.Insert("PeriodEnding",DesiredElement_[0].EndPeriod_);
		RunBackgroundJob1(
			"RecalculationPlanningAssistant",
			ProcedureParameters);
	ElsIf   FormattedStringURL = "SetAsActive" Then
		PlanningAssistantShowInTable(DesiredElement_[0].PlanProfile,DesiredElement_[0].StartPeriod);
	ElsIf   FormattedStringURL = "Adjust" Then
		NecessaryElementOfKoriktirovka = TableOfAdjustments.FindRows(New Structure("Name",Item.Name));
		If   NecessaryElementOfKoriktirovka.Count() > 0 Then 
			PrametersOfForm = New Structure("Key",NecessaryElementOfKoriktirovka[0].Document);
			OpenForm("Document.AdjustmentOfPlannedDemand.ObjectForm",PrametersOfForm);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateCaption(Var_Group, SectionCollapsed,TitleTitle,HeaderType="Update_")
	TitleGroup = Items.Add("HeaderGroup_"+Var_Group.Name,Type("FormGroup"),Var_Group);
	TitleGroup.Type = FormGroupType.UsualGroup;
	TitleGroup.Representation = UsualGroupRepresentation.None;
	TitleGroup.Group = ChildFormItemsGroup.AlwaysHorizontal;
	TitleGroup.ShowTitle = False;
	Title1 = New FormattedString(TitleTitle,New Font(,,45),,,);
	Item = Items.Add("Picture" + Var_Group.Name, Type("FormDecoration"), TitleGroup);
	Item.Type = FormDecorationType.Picture;
	Item.Hyperlink = True;
	
	If SectionCollapsed  Then
		Item.Picture = PictureLib.RightArrow;
	Else
		Item.Picture = PictureLib.DownArrow;
	EndIf;
	
	Item.PictureSize = PictureSize.AutoSize;
	Item.SetAction("Click", "Attachable_ProcessPictureClick");
	Item.ToolTip = NStr("vi = 'Mở/ đóng thẻ';
						|ru = 'Развернуть/свернуть раздел';
						|en = 'Expand or collapse section'; fa = 'Expand or collapse section';
						|it = 'Espandere/ridurre la sezione';
						|pl = 'Rozwinąć/zwinąć rozdział';
						|tr = 'Bölümü genişlet/daralt'");
	
	Item = Items.Add("Picture1" + Var_Group.Name, Type("FormDecoration"), TitleGroup);
	Item.Type = FormDecorationType.Picture;
	If HeaderType = "Update_" Then
		Item.Picture = PictureLib.Information16;
	ElsIf HeaderType = "Deficit" Then 
		Item.Picture = PictureLib.NavigationUpdate;
	ElsIf HeaderType = "Adjusting" Then 
		Item.Picture = PictureLib.ShowData;
	EndIf;
	Item.Visible = True;
	
	
	Item = Items.Add("Title" + Var_Group.Name, Type("FormDecoration"), TitleGroup);
	Item.Type = FormDecorationType.Label;
	Item.HorizontalAlign = ItemHorizontalLocation.Left;
	Item.Title  = Title1;
EndProcedure


// Parameters:
// 	Item - FormDecoration -
&AtClient
Procedure Attachable_ProcessPictureClick(Item)

	SwitchPicture(Item.Name);
	
EndProcedure

&AtServer
Procedure SwitchPicture(Var_Title)
	
	Item = Items.Find(Var_Title);
	
	If Item.Picture = PictureLib.RightArrow Then
		Item.Picture = PictureLib.DownArrow;
	Else
		Item.Picture = PictureLib.RightArrow;
	EndIf;
	
	ChangingVisibilityOfHelperElement(Item.Parent.Parent);
	
EndProcedure

&AtServer
Procedure ChangingVisibilityOfHelperElement(Item)
	
	HelperSBody = Items.Find("HelperSBody"+Item.Name);
	
	If HelperSBody <> Undefined Then
		HelperSBody.Visible = Not HelperSBody.Visible
	EndIf;
	
EndProcedure

&AtServer
Procedure HideSchedulingAssistantClickOnServer()
	
	Items.PlanningWizard.Visible = Not Items.PlanningWizard.Visible;
	Items.HidePlanningWizard.Title = ?(Items.PlanningWizard.Visible,NStr("vi = 'Ẩn Trợ giúp Bộ lập kế hoạch';
																		|ru = 'Скрыть Помощник Планирования';
																		|en = 'Hide Planning Wizard'; fa = 'پنهان کردن دستیار برنامه‌ریزی';
																		|it = 'Nascondere Assistente di Pianificazione';
																		|pl = 'Ukryj Pomocnik Planowania';
																		|tr = 'Planlama Sihirbazı''nı Gizle'"),NStr("vi = 'Hiển thị người trợ giúp lập kế hoạch';
																											|ru = 'Показать Помощник Планирования';
																											|en = 'Show Planning Wizard'; fa = 'Show Planning Wizard';
																											|it = 'Mostrare Assistente di Pianificazione';
																											|pl = 'Pokaż Pomocnik Planowania';
																											|tr = 'Planlama Sihirbazı''nı Göster'"));		
	
EndProcedure

&AtClient
Procedure HidePlanningWizardClick(Item)
	
	HideSchedulingAssistantClickOnServer();
	
EndProcedure

&AtClient
Procedure FillInByShortages(Command)
	
	SetTheShortageRecalculationIndicator = True;
	UpdateStageTreeOnServer();
	RecalculationElement.Clear();
	EnableFillingByShortagesPlanningWizard =  Not EnableFillingByShortagesPlanningWizard;
	FillByServerDeficits();
	DeficitAnalysis();
	
EndProcedure

&AtServer
Procedure FillByServerDeficits()
	
	RecalculationButton = Items.Find("RecalculateAllPlans");
	If RecalculationButton = Undefined Then
		Return;
	EndIf;
	RecalculationButton.Title = ?(Not EnableFillingByShortagesPlanningWizard,
	NStr("vi = 'Tính toán lại tất cả các kế hoạch cho thâm hụt';
		|ru = 'Перерасчитать по дефицитам все планы';
		|en = 'Recalculate all plans by shortages'; fa = 'Recalculate all plans by shortages';
		|it = 'Ricalcolare per deficit tutti i piani';
		|pl = 'Przelicz wg niedoborów wszystkie plany';
		|tr = 'Mali açığa göre tüm planları yeniden hesapla'"),
	NStr("vi = 'Dừng tính toán lại các kế hoạch';
		|ru = 'Остановить перерасчет планов';
		|en = 'Stop plan recalculation'; fa = 'Stop plan recalculation';
		|it = 'Arrestare il ricalcolo dei piani';
		|pl = 'Zatrzymaj przeliczenie planów';
		|tr = 'Yeniden hesaplama planlarını durdur'"));
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		ThePeriodBeginningEndingDuringTheChange(Items.PeriodBeginning);
	ElsIf Item.Name = "sh_ShamsiInput_PeriodEnding" Then
		ThePeriodBeginningEndingDuringTheChange(Items.PeriodEnd);
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
