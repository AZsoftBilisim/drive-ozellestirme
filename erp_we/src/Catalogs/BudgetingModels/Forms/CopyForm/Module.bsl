
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("CopyingModel") Then
		CopyingModel = Parameters.CopyingModel;
	EndIf;
	
	If Parameters.Property("BudgetingModel") Then
		BudgetingModel = Parameters.BudgetingModel;
	EndIf;	

	FillInTreeOfBudgetTypes();
	If GetFunctionalOption("UseBudgetProcess") Then
		FillInTreeStagesOfBudgetPreparation();
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Let's open the top level of the tree
	TreeItems = BudgetProfiles.GetItems();
	For Each TreeItem In TreeItems Do
		Items.BudgetProfiles.Expand(TreeItem.GetID());
	EndDo;
	TreeItems = BudgetingSteps.GetItems();
	For Each TreeItem In TreeItems Do
		Items.BudgetingSteps.Expand(TreeItem.GetID());
	EndDo;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetProfiles

&AtClient
Procedure BudgetProfilesFlagOnChange(Item)
	
	CurrentData = Items.BudgetProfiles.CurrentData;
	SetSubordinateMarks(CurrentData, "Flag");
	SetParentMarks(CurrentData, "Flag");

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetingSteps

&AtClient
Procedure BudgetingStepsFlagOnChange(Item)
	
	CurrentData = Items.BudgetingSteps.CurrentData;
	SetSubordinateMarks(CurrentData, "Flag");
	SetParentMarks(CurrentData, "Flag");

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckAll(Command)
	
	Tree = Undefined;
	If Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageTypesOfBudgets Then
		Tree = BudgetProfiles;
	ElsIf  Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageStagesOfBudgetPreparation Then
		Tree = BudgetingSteps;
	Else
		Return;
	EndIf;
	
	For Each String In Tree.GetItems() Do
		String.Flag = True;
		SetSubordinateMarks(String, "Flag");
	EndDo;

EndProcedure

&AtClient
Procedure UncheckAll(Command)
	
	Tree = Undefined;
	If Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageTypesOfBudgets Then
		Tree = BudgetProfiles;
	ElsIf  Items.PagesBudgetStepsProfiles.CurrentPage = Items.PageStagesOfBudgetPreparation Then
		Tree = BudgetingSteps;
	Else
		Return;
	EndIf;

	For Each String In Tree.GetItems() Do
		String.Flag = False;
		SetSubordinateMarks(String, "Flag");
	EndDo;

EndProcedure

&AtClient
Procedure Copy(Command)
	
	SelectedTypesOfBudgets = GetSelectedSelectionItems(BudgetProfiles,"Ref");
	SelectedStagesOfBudgetPreparation_ = GetSelectedSelectionItems(BudgetingSteps,"Ref");
	
	CopyAtServer(BudgetingModel, CopyingModel, SelectedTypesOfBudgets, SelectedStagesOfBudgetPreparation_, CopyLimits);
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTreeOfBudgetTypes()
	
	Return; // it is not used in international delivery
	
EndProcedure

// Sets the marking state for subordinate rows of the value tree
// row, depending on the marking of the current row.
//
// Parameters:
//  CurRow - ValueTreeRow - a string of the value tree.
//  CheckBoxName - String - Name of the tree column.
// 
&AtClient
Procedure SetSubordinateMarks(CurRow, CheckBoxName)
	
	SubordinateItems = CurRow.GetItems();
	
	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		String[CheckBoxName] = CurRow[CheckBoxName];
		
		SetSubordinateMarks(String, CheckBoxName);
		
	EndDo;
		
EndProcedure

&AtServerNoContext
Procedure CopyAtServer(BudgetingModel, CopyingModel, SelectedTypesOfBudgets, SelectedStagesOfBudgetPreparation_ = Undefined, CopyLimits=False)
	
	LanguageCode = Common.DefaultLanguageCode();
	BeginTransaction();
	
	Try

		RefsMap = New Map();
		
		// Copying types of budgets
		CopyBudgetTypes(BudgetingModel,SelectedTypesOfBudgets,RefsMap);
		
		// We delete the Cur and copy the stages of budget preparation from the copy source model.
		If Not SelectedStagesOfBudgetPreparation_ = Undefined Then
			CopyBudgetStages(BudgetingModel,SelectedStagesOfBudgetPreparation_,RefsMap);
		EndIf;
		If CopyLimits Then
			GroupMapping = New Map;
			
			Query = New Query;
			Query.Text = "SELECT
			|	BudgetingLimits.Ref,
			|	BudgetingLimits.IsFolder AS IsFolder,
			|	BudgetingLimits.Parent
			|FROM
			|	Catalog.BudgetingLimits AS BudgetingLimits
			|WHERE
			|	BudgetingLimits.Owner = &Owner
			|
			|ORDER BY
			|	IsFolder HIERARCHY";
			
			Query.SetParameter("Owner", CopyingModel);
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				CopyOfLimit = Selection.Ref.Copy(); // CatalogObject.BudgetingLimits -
				CopyOfLimit.Owner = BudgetingModel;
				If Not Selection.Parent.IsEmpty() Then
					CopyOfLimit.Parent = GroupMapping[Selection.Parent];
				EndIf;
				CopyOfLimit.Write();
				
				If Selection.IsFolder Then
					GroupMapping.Insert(Selection.Ref, CopyOfLimit.Ref);
				EndIf;
			EndDo;
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		LREvent = NStr("vi = 'Sao chép mô hình ngân sách';
						|ru = 'Копирование модели бюджетирования';
						|en = 'Copy budgeting model'; fa = 'Copy budgeting model';
						|it = 'Copia del modello di budgeting';
						|pl = 'Kopiowanie modelu budżetowania';
						|tr = 'Bütçe modellerinin kopyalanması'", LanguageCode);
		WriteLogEvent(LREvent,
				EventLogLevel.Error,
				Metadata.Catalogs.BudgetingModels,,
				ErrorText);
		Raise;
	EndTry;
	
EndProcedure

// Returns a tree of elements of financial statements.
// 
// Parameters:
// 	SelectedTypesOfBudgets - Array of CatalogRef.BudgetProfiles - 
// Returns:
// 	ValueTree - :
// 	 *Ref - CatalogRef.FinancialReportItems - 
// 	 *Owner - CatalogRef.BudgetProfiles - 
//
&AtServerNoContext
Function TreeOfElementsOfFinancialStatements(SelectedTypesOfBudgets)
	Query = New Query;
	Query.Text = "SELECT
		|	FinancialReportItems.Ref AS Ref,
		|	FinancialReportItems.Owner AS Owner
		|FROM
		|	Catalog.FinancialReportItems AS FinancialReportItems
		|WHERE
		|	FinancialReportItems.Owner IN(&Owner)
		|TOTALS BY
		|	Owner,
		|	Ref HIERARCHY";
	
	Query.SetParameter("Owner",SelectedTypesOfBudgets);
	
	Tree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	Return Tree;
EndFunction

&AtServerNoContext
Procedure CopyBudgetTypes(BudgetingModel,SelectedTypesOfBudgets,RefsMap=Undefined)
	
	If RefsMap = Undefined Then
		RefsMap = New Map();
	EndIf;
	ElementsWithBrokenLinks = New Array();
	
	For Each Page1 In SelectedTypesOfBudgets Do
		
		If Not RefsMap.Get(Page1) = Undefined Then
			Continue;
		EndIf;
		
		Copy = Page1.Copy(); // CatalogObject.BudgetProfiles - 
		Copy.Owner = BudgetingModel;
		If ValueIsFilled(Copy.Parent) Then
			Copy.Parent = RefsMap.Get(Copy.Parent);
		EndIf;
		Copy.Write();
		RefsMap.Insert(Page1,Copy.Ref);
		
	EndDo;
	
	FOElements = TreeOfElementsOfFinancialStatements(SelectedTypesOfBudgets);
	
	For Each BudgetProfile In FOElements.Rows Do
		Owner = RefsMap.Get(BudgetProfile.Owner);
		For Each FOElement In BudgetProfile.Rows Do
			CopyOfFOElement = FOElement.Ref.Copy(); // CatalogObject.FinancialReportItems - 
			CopyOfFOElement.Owner = Owner;
			CopyOfFOElement.Write();
			RefsMap.Insert(FOElement.Ref,CopyOfFOElement.Ref);
			CopyFOElement(FOElement,Owner,CopyOfFOElement.Ref, RefsMap,ElementsWithBrokenLinks);	
		EndDo;
		
	EndDo;
	
	For Each FOElement In ElementsWithBrokenLinks Do
		FOElement = FOElement.GetObject(); // CatalogObject.FinancialReportItems - 
		ProcessTsOfFOElement(FOElement,RefsMap);
		FOElement.Write();
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure CopyBudgetStages(BudgetingModel,SelectedStagesOfBudgetPreparation_,RefsMap, MatchingStageReferences=Undefined)
	
	If MatchingStageReferences = Undefined Then
		MatchingStageReferences = New Map();
	EndIf;
	
	For Each Page1 In SelectedStagesOfBudgetPreparation_ Do
		
		If Not MatchingStageReferences.Get(Page1) = Undefined Then
			Continue;
		EndIf;
		
		Copy = Page1.Copy(); // CatalogObject.BudgetingSteps - 
		Copy.Owner = BudgetingModel;
		If ValueIsFilled(Copy.Parent) Then
			Copy.Parent = MatchingStageReferences.Get(Copy.Parent);
		EndIf;
		//@skip-check query-in-loop
		ProcessStageActionSettings(BudgetingModel,Copy,RefsMap,MatchingStageReferences);
		Copy.Write();
		MatchingStageReferences.Insert(Page1,Copy.Ref);
		
	EndDo;
		
EndProcedure

&AtServer
Procedure FillInTreeStagesOfBudgetPreparation()
	
	Return; // it is not used in international delivery
	
EndProcedure


// LongDesc
// 
// Parameters:
// 	TreeRow - See CopyFOElement.FOElement
// Returns:
// 	ValueTreeRowCollection of See CopyFOElement.FOElement
//
&AtServerNoContext
Function CollectionOfFinancialStatementTreeRows(TreeRow)
	Return TreeRow.Rows;
EndFunction

// Recursively copies the elements of the financial statements.
// 
// Parameters:
// 	FOElement - ValueTreeRow - tree row with columns:
// 	 *Ref - CatalogRef.FinancialReportItems -
// 	 *Owner - CatalogRef.BudgetProfiles -
// 	Owner - CatalogRef.BudgetProfiles - new budget type, owner of the report elements that are being created.
// 	Parent - CatalogRef.FinancialReportItems - 
// 	RefsMap - Map of KeyAndValue, Undefined - matching, where:
// 	 *Key - CatalogRef.FinancialReportItems -
// 	 *Value - CatalogRef.BudgetProfiles -
// 	ElementsWithBrokenLinks - Array of CatalogRef.FinancialReportItems -
&AtServerNoContext
Procedure CopyFOElement(FOElement, Owner, Parent, RefsMap, ElementsWithBrokenLinks)
	
	RowsCollection = CollectionOfFinancialStatementTreeRows(FOElement);
	For Each SubordinateElementOfFO In RowsCollection Do
		If SubordinateElementOfFO.Ref = FOElement.Ref Then
			Continue;
		EndIf;
		
		CopyOfFOElement = SubordinateElementOfFO.Ref.Copy(); // CatalogObject.FinancialReportItems -
		CopyOfFOElement.Owner = Owner;
		CopyOfFOElement.Parent = Parent;
		Errors = ProcessTsOfFOElement(CopyOfFOElement,RefsMap);
		CopyOfFOElement.DataExchange.Load = True;
		CopyOfFOElement.Write();
		If Errors Then 
			ElementsWithBrokenLinks.Add(CopyOfFOElement.Ref);
		EndIf;

		RefsMap.Insert(SubordinateElementOfFO.Ref,CopyOfFOElement.Ref); 
		CopyFOElement(SubordinateElementOfFO,Owner,CopyOfFOElement.Ref, RefsMap, ElementsWithBrokenLinks);	
	EndDo;
		
EndProcedure

&AtServerNoContext
Function ProcessTsOfFOElement(FOElement,RefsMap)
	
	Errors = False;
		
	// Bypassing all PM
	TabbedMetadata = Metadata.Catalogs.FinancialReportItems.TabularSections;
	TypeToProcess_ = Type("CatalogRef.FinancialReportItems");
	For Each TS In TabbedMetadata Do
		ColumnsForProcessing = New Array();
		For Each Column In TS.Attributes Do
			If Not Column.Type.Types().Find(TypeToProcess_) = Undefined Then
				ColumnsForProcessing.Add(Column.Name);	
			EndIf;
		EndDo;
		TabPart = FOElement[TS.Name];
		
		For Each Page1 In TabPart Do
			For Each NameColumn In ColumnsForProcessing Do
				If Not TypeOf(Page1[NameColumn]) = TypeToProcess_ Then
					Continue;
				EndIf;
				Replacement = RefsMap.Get(Page1[NameColumn]);
				If Not Replacement = Undefined Then
					Page1[NameColumn] = Replacement;
				Else
					Errors = True;
				EndIf;
			EndDo;
		EndDo;
		
	EndDo;

	If ValueIsFilled(FOElement.LinkedItem1) Then
		Replacement = RefsMap.Get(FOElement.LinkedItem1);
		If Not Replacement = Undefined Then
			FOElement.LinkedItem1 = RefsMap.Get(FOElement.LinkedItem1);
		Else
			Errors = True;
		EndIf;
	EndIf;

	Return Errors;
	
EndFunction
&AtServerNoContext
Procedure ProcessStageActionSettings(BudgetingModel,Stage,RefsMap,MatchingStageReferences)
	
	If Stage.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm Then
		
		SettingOfAction = Stage.SettingOfAction.Get();
		If TypeOf(SettingOfAction) <> Type("ValueTable") Then
			Return;
		EndIf;
		
		SearchParameters = New Structure;
		SearchParameters.Insert("Name","BudgetProfiles");
		Rows = SettingOfAction.FindRows(SearchParameters);
		If Rows.Count() = 0 Then 
			Return;
		EndIf;
		
		VTTypesOfBudgets = Rows[0].Value;
		
		TypesOfBudgetsToCopy = New Array();
		For Each Page1 In VTTypesOfBudgets Do
			Replacement = RefsMap.Get(Page1.BudgetProfile);
			If ValueIsFilled(Replacement) Then
				Page1.BudgetProfile = Replacement;
			Else
				If TypesOfBudgetsToCopy.Find(Page1.BudgetProfile) = Undefined Then
					TypesOfBudgetsToCopy.Add(Page1.BudgetProfile);
				EndIf;
			EndIf;
		EndDo;
		
		Query = New Query;
		Query.Text = "SELECT
		               |	BudgetProfiles.Ref AS Ref,
		               |	TRUE AS Flag
		               |FROM
		               |	Catalog.BudgetProfiles AS BudgetProfiles
		               |WHERE
		               |	BudgetProfiles.Ref IN(&TypesOfBudgetsToCopy)
		               |TOTALS
		               |	MAX(Flag)
		               |BY
		               |	Ref HIERARCHY";
					   
		Query.SetParameter("TypesOfBudgetsToCopy",TypesOfBudgetsToCopy);
		
		TypesOfBudgetsTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
		TypesOfBudgetsToCopy = GetSelectedSelectionItems(TypesOfBudgetsTree,"Ref");
				
		CopyBudgetTypes(BudgetingModel,TypesOfBudgetsToCopy,RefsMap);
		
		For Each Page1 In VTTypesOfBudgets Do
			Replacement = RefsMap.Get(Page1.BudgetProfile);
			If ValueIsFilled(Replacement) Then
				Page1.BudgetProfile = Replacement;
			EndIf;
		EndDo;
			
		Stage.SettingOfAction = New ValueStorage(SettingOfAction);
		
	ElsIf Stage.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets Then
		
		SettingOfAction = Stage.SettingOfAction.Get();
		If TypeOf(SettingOfAction) <> Type("ValueTable") Then
			Return;
		EndIf;

		SearchParameters = New Structure;
		SearchParameters.Insert("Name","ApprovedStagesOfBudgetPreparation");
		Rows = SettingOfAction.FindRows(SearchParameters);
		If Rows.Count() = 0 Then 
			Return;
		EndIf;
		
		ApprovedStages = Rows[0].Value;
		StepsToCopy = New Array();
		
		For Each Page1 In ApprovedStages Do
			Replacement = MatchingStageReferences.Get(Page1.Value);
			If ValueIsFilled(Replacement) Then
				Page1.Value = Replacement;
			Else
				If StepsToCopy.Find(Page1.Value) = Undefined Then
					StepsToCopy.Add(Page1.Value);
				EndIf;
			EndIf;
		EndDo;	
		
		Query = New Query;
		Query.Text = "SELECT
		               |	BudgetingSteps.Ref AS Ref,
		               |	TRUE AS Flag
		               |FROM
		               |	Catalog.BudgetingSteps AS BudgetingSteps
		               |WHERE
		               |	BudgetingSteps.Ref IN(&StepsToCopy)
		               |TOTALS
		               |	MAX(Flag)
		               |BY
		               |	Ref HIERARCHY";
					   
		Query.SetParameter("StepsToCopy",StepsToCopy);
		
		StagesTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
		
		StepsToCopy = GetSelectedSelectionItems(StagesTree,"Ref");
		
		CopyBudgetStages(BudgetingModel,StepsToCopy,RefsMap, MatchingStageReferences);
		
		For Each Page1 In ApprovedStages Do
			Replacement = MatchingStageReferences.Get(Page1.Value);
			If ValueIsFilled(Replacement) Then
				Page1.Value = Replacement;
			EndIf;
		EndDo;	

		Stage.SettingOfAction = New ValueStorage(SettingOfAction);
		
	EndIf;
	
EndProcedure
// Sets the marking state for parent rows of the value tree
// row, depending on the marking of the current row.
//
// Parameters:
//  CurRow      - ValueTreeRow
// 
&AtClient
Procedure SetParentMarks(CurRow, CheckBoxName)
	
	Parent = CurRow.GetParent();
	If Parent = Undefined Then
		Return;
	EndIf; 
	
	CurState = Parent[CheckBoxName];
	
	EnabledItemsFound  = False;
	DisabledItemsFound = False;
	
	For Each String In Parent.GetItems() Do
		If String[CheckBoxName] = 0 Then
			DisabledItemsFound = True;
		ElsIf String[CheckBoxName] = 1
			Or String[CheckBoxName] = 2 Then
			EnabledItemsFound  = True;
		EndIf; 
		If EnabledItemsFound And DisabledItemsFound Then
			Break;
		EndIf; 
	EndDo;
	
	If EnabledItemsFound And DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound And (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) And DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) And (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;
	
	If Enable = CurState Then
		Return;
	Else
		Parent[CheckBoxName] = Enable;
		SetParentMarks(Parent, CheckBoxName);
	EndIf; 
	
EndProcedure

&AtClientAtServerNoContext
Function GetSelectedSelectionItems(SelectionTree_,ColumnName)
	
	SelectedValues = New Array;
	If TypeOf(SelectionTree_) = Type("FormDataTree") Or TypeOf(SelectionTree_) = Type("FormDataTreeItem") Then
		TreeItems = SelectionTree_.GetItems();
	Else
		TreeItems = SelectionTree_.Rows;	
	EndIf;
	For Each TreeItems In TreeItems Do
		If TreeItems.Flag Then
			SelectedValues.Add(TreeItems[ColumnName]);
			SubordinateValues = GetSelectedSelectionItems(TreeItems,ColumnName);
			For Each Value In SubordinateValues Do
				SelectedValues.Add(Value);
			EndDo;
		EndIf;
	EndDo;
	
	Return SelectedValues;
	
EndFunction

#EndRegion
