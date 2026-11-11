#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ListOfProperties = CostGroupsClientServer.CostGroupFields();
	FillPropertyValues(ThisForm, Parameters, ListOfProperties);
	
	If ValueIsFilled(ExpenseGroup) Then
		Title = ExpenseGroup;
	Else
		Title = CostGroupsServer.CostGroupPresentation(Parameters);
	EndIf;
	
	OnlyViewItems = Not AccessRight("Update", Metadata.Catalogs.ProductionLots);
	
	FieldList = CostGroupsServer.ListOfFieldsByCostGrouping(Document, Parameters.GroupCosts);
	TextNotUsed = NStr("vi = '<không sử dụng>';
						|ru = '<не используется>';
						|en = '<not used>'; fa = '<استفاده نمی‌شود>';
						|it = '<non viene utilizzato>';
						|pl = '<nie używa się>';
						|tr = '<kullanılmayan>'");
	
	ItemArray = New Array;
	ItemArray.Add("GroupCosts");
	ItemArray.Add("Products");
	ItemArray.Add("Characteristic");
	ItemArray.Add("Series");
	ItemArray.Add("BillOfMaterials");
	ItemArray.Add("Purpose");
	
	For Each CurItem In ItemArray Do
		Items[CurItem].ReadOnly = OnlyViewItems;
		If FieldList.FindByValue(CurItem) = Undefined Then
			Items[CurItem].InputHint = TextNotUsed;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion