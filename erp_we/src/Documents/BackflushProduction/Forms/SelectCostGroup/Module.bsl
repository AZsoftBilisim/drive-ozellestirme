#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DisplayGiversInCostGroup = Parameters.DisplayGiversInCostGroup;
	
	FieldList = Documents.BackflushProduction.ListOfCostGroupFields(Parameters.GroupCosts);
	
	CostGroupHeader = "";
	For Each CurField In FieldList Do
		
		If ValueIsFilled(CurField.Presentation) Then
			If Not DisplayGiversInCostGroup
				And CurField.Value = "MaterialProviderCompany" Then
				Continue;
			EndIf;
			CostGroupHeader = CostGroupHeader + CurField.Presentation + " / ";
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(CostGroupHeader) Then
		CostGroupHeader = Left(CostGroupHeader, StrLen(CostGroupHeader) - 3);
		CostGroupHeader = NStr("vi = 'Nhóm chi phí';
								|ru = 'Группа затрат';
								|en = 'Cost group'; fa = 'گروه بها';
								|it = 'Gruppo di spese';
								|pl = 'Grupa kosztów';
								|tr = 'Maliyet grubu'") + " (" + CostGroupHeader + ")";
	Else
		CostGroupHeader = NStr("vi = 'Nhóm chi phí';
								|ru = 'Группа затрат';
								|en = 'Cost group'; fa = 'گروه بها';
								|it = 'Gruppo di spese';
								|pl = 'Grupa kosztów';
								|tr = 'Maliyet grubu'");
	EndIf;
	
	Items.ListOfGroupsExpenseGroup.Title = CostGroupHeader;
	
	ListOfGroups.Load(GetFromTempStorage(Parameters.CostGroupStorageAddress));
	
	For Each GroupString In ListOfGroups Do
		
		If Parameters.CostGroupNumber = GroupString.CostGroupNumber Then
			Items.ListOfGroups.CurrentRow = GroupString.GetID();
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListOfGroupsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessGroupSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectGroup(Command)
	
	ProcessGroupSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessGroupSelection()

	CurrentData = Items.ListOfGroups.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("ExpenseGroup", CurrentData.ExpenseGroup);
	ChoiceParameters.Insert("CostGroupNumber", CurrentData.CostGroupNumber);
	ChoiceParameters.Insert("LineOfBusiness", CurrentData.LineOfBusiness);
	ChoiceParameters.Insert("InternalSubcontracting", CurrentData.InternalSubcontracting);
	ChoiceParameters.Insert("MaterialProviderCompany",    CurrentData.MaterialProviderCompany);
	Close(ChoiceParameters);

EndProcedure

#EndRegion
