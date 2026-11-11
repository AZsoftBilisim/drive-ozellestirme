
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Owner") Then
			BudgetingModel = Parameters.Filter.Owner;
			ModelReference = GetURL(BudgetingModel);
			
			HeaderParts = New Array;
			HeaderParts.Add(NStr("vi = 'Mô hình ngân sách';
								|ru = 'Модель бюджетирования';
								|en = 'Budgeting model'; fa = 'مدل بودجه‌بندی';
								|it = 'Modello di budgeting';
								|pl = 'Model budżetowania';
								|tr = 'Bütçeleme modeli'") + ":");
			HeaderParts.Add(New FormattedString(String(BudgetingModel), , , , ModelReference));
			If AccessRight("View", Metadata.Reports.BudgetingProcessmonitor)
			   And AccessRight("View", Metadata.Reports.PerformanceOfBudgetProcessTasks) Then
				HeaderParts.Add(" ");
				HeaderParts.Add("(");
				HeaderParts.Add(New FormattedString(NStr("vi = 'Đánh giá quy trình ngân sách';
														|ru = 'Обзор бюджетного процесса';
														|en = 'Budget process overview'; fa = 'نمای کلی فرایند بودجه';
														|it = 'Revisione del processo di budgeting';
														|pl = 'Przegląd procesu budżetowego';
														|tr = 'Bütçe sürecinin gözden geçirilmesi'"), , , , "Overview"));
				HeaderParts.Add(")");
			EndIf;
			
			Items.LabelBudgetingModel.Title = New FormattedString(HeaderParts);
		EndIf;
	EndIf;
	
	ModelIsDefinedBySelection = ValueIsFilled(BudgetingModel);
	Items.InformationAboutBudgetingModel.Visible = ModelIsDefinedBySelection;
	Items.BudgetingModel.Visible = Not ModelIsDefinedBySelection;
	
	If Not ValueIsFilled(BudgetingModel) Then
		BudgetingModel = Catalogs.BudgetingModels.DefaultBudgetingModel();
		CommonClientServer.SetDynamicListFilterItem(
			List, "Owner", BudgetingModel,,, ValueIsFilled(BudgetingModel));
	EndIf;
	
	ChangingStagesOfBudgetPreparation = AccessRight("Update", Metadata.Catalogs.BudgetingSteps);
	If Items.Find("FormMoveHigher") <> Undefined Then
		Items.FormMoveHigher.Visible = ChangingStagesOfBudgetPreparation;
	EndIf;
	If Items.Find("FormMoveLower") <> Undefined Then
		Items.FormMoveLower.Visible = ChangingStagesOfBudgetPreparation;
	EndIf;
	If Items.Find("ListContextMenuCreate") <> Undefined Then
		Items.ListContextMenuCreate.Enabled = ChangingStagesOfBudgetPreparation;
	EndIf;
	If Items.Find("ListContextMenuCreateFolder") <> Undefined Then
		Items.ListContextMenuCreateFolder.Enabled = ChangingStagesOfBudgetPreparation;
	EndIf;
	If Items.Find("ListContextMenuCopy") <> Undefined Then
		Items.ListContextMenuCopy.Enabled = ChangingStagesOfBudgetPreparation;
	EndIf;
	If Items.Find("ListContextMenuMoveItem") <> Undefined Then
		Items.ListContextMenuMoveItem.Enabled = ChangingStagesOfBudgetPreparation;
	EndIf;
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LabelBudgetingModelURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "Overview" Then
		OpenForm("Report.BudgetingProcessmonitor.Form", 
				New Structure("BudgetingModel, GenerateOnOpen", BudgetingModel, True), 
				ThisObject, 
				BudgetingModel);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure DisplaceElement(Ref, Direction)
	
	Catalogs.BudgetingSteps.ShiftElement(Ref, Direction);
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure MoveHigher(Command)
	
	DisplaceElement(Items.List.CurrentRow, -1);
	
EndProcedure

&AtClient
Procedure MoveLower(Command)
	
	DisplaceElement(Items.List.CurrentRow, 1);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Owner", BudgetingModel,,, ValueIsFilled(BudgetingModel));
	
EndProcedure

&AtClient
Procedure ExpandAll(Command)
	
	ShowAllLevelsOfHierarchy();

EndProcedure

&AtClient
Procedure CollapseAll(Command)
	
	ShowHierarchyLevel(2);

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

#Region Private

&AtClient
Function ShowHierarchyLevel(HierarchyLevel)
	
	ResultStructure = GetTopTwoLevelsOfCatHierarchy(BudgetingModel);
	Rows = ResultStructure.UpperLevelsOfCatHierarchy;
	CatLevels = ResultStructure.LevelsOfCatHierarchy;
		
    Qty = Rows.Count();
	Cnt = 0;
    While Cnt < Qty Do

        CurRow = Rows[Cnt];

		If Items.List.Expanded(CurRow) And CatLevels.Get(CurRow) >= HierarchyLevel Then
			Items.List.Collapse(CurRow);
		ElsIf Not Items.List.Expanded(CurRow) And CatLevels.Get(CurRow) < HierarchyLevel Then
			Items.List.Expand(CurRow);
		EndIf;

        Cnt = Cnt + 1;

    EndDo;

EndFunction

&AtClient
Function ShowAllLevelsOfHierarchy()
	
	ResultStructure = GetTopTwoLevelsOfCatHierarchy(BudgetingModel);
	Rows = ResultStructure.UpperLevelsOfCatHierarchy;
	CatLevels = ResultStructure.LevelsOfCatHierarchy;
		
    Qty = Rows.Count();
	Cnt = 0;
    While Cnt < Qty Do

        CurRow = Rows[Cnt];
		Cnt = Cnt + 1;
		
		If CatLevels.Get(CurRow) <> 1 Then
			Continue;
		EndIf;

		Items.List.Expand(CurRow,True);

    EndDo;

EndFunction

&AtServerNoContext
Function GetTopTwoLevelsOfCatHierarchy(BudgetingModel)
		
	Query = New Query;
	Query.Text =  "SELECT
	                |	BudgetingSteps.Ref
	                |INTO FirstLevel
	                |FROM
	                |	Catalog.BudgetingSteps AS BudgetingSteps
	                |WHERE
	                |	BudgetingSteps.Owner = &Owner
	                |	AND BudgetingSteps.Parent = VALUE(Catalog.BudgetingSteps.EmptyRef)
	                |;
	                |
	                |////////////////////////////////////////////////////////////////////////////////
	                |SELECT
	                |	FirstLevel.Ref,
	                |	1 AS Level
	                |FROM
	                |	FirstLevel AS FirstLevel
	                |
	                |UNION ALL
	                |
	                |SELECT
	                |	BudgetingSteps.Ref,
	                |	2
	                |FROM
	                |	Catalog.BudgetingSteps AS BudgetingSteps
	                |WHERE
	                |	BudgetingSteps.Parent IN
	                |			(SELECT
	                |				A.Ref
	                |			FROM
	                |				FirstLevel AS A)";
					
	Query.SetParameter("Owner",BudgetingModel);
	
	Selection = Query.Execute().Select();
	
	Result = New Structure;
	UpperLevelsOfCatHierarchy = New Array();
	LevelsOfCatHierarchy = New Map;
	
	While Selection.Next() Do
		UpperLevelsOfCatHierarchy.Add(Selection.Ref);
		LevelsOfCatHierarchy.Insert(Selection.Ref,Selection.Level);
	EndDo;
	
	Result.Insert("UpperLevelsOfCatHierarchy",UpperLevelsOfCatHierarchy);
	Result.Insert("LevelsOfCatHierarchy",LevelsOfCatHierarchy);
	
	Return Result;
	
EndFunction

#EndRegion

