
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("InstructionList") Then
		MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẩu này.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено.';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane.';
							|tr = 'Bu formun doğrudan açılması sağlanmamaktadır.'");
		Raise MessageText;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Ref AS Code,
	|	LongDesc,
	|	CannotBeUsedTogether,
	|	Ref IN (&SelectedInstructions) AS Check
	|FROM
	|	Catalog.InstructionsForBank
	|";
	Query.SetParameter("SelectedInstructions", Parameters.InstructionList);
	InstructionList.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure InstructionListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(,InstructionList[RowSelected].Code);
	
EndProcedure

&AtClient
Procedure InstructionListCheckOnChange(Item)
	
	CurrentData = Items.InstructionList.CurrentData;
	If CurrentData.Check Then
		CannotBeUsedTogether = CurrentData.CannotBeUsedTogether;
		MarkedLines = InstructionList.FindRows(New Structure("Check", True));
		For Each InstructionLine In MarkedLines Do
			If StrFind(CannotBeUsedTogether, String(InstructionLine.Code)) Then
				InstructionLine.Check = False;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	MarkedInstructions = New Array;
	For Each MarkedInstruction In InstructionList.FindRows(New Structure("Check", True)) Do
		MarkedInstructions.Add(MarkedInstruction.Code);
	EndDo;
	
	Close(MarkedInstructions);
	
EndProcedure

#EndRegion