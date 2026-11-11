
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var ValueOfHeaderParameter;
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DocumentsList.LoadValues(Parameters.DocumentsList.UnloadValues());
	
	If Parameters.Property("Title", ValueOfHeaderParameter) Then
		Title = ValueOfHeaderParameter;
	Else
		Title = NStr("vi = 'Đơn hàng (%DocumentsCount%)';
					|ru = 'Заказы (%DocumentsCount%)';
					|en = 'Orders (%DocumentsCount%)'; fa = 'Orders (%DocumentsCount%)';
					|it = 'Ordini (%DocumentsCount%)';
					|pl = 'Zamówienia (%DocumentsCount%)';
					|tr = 'Siparişler (%DocumentsCount%)'");
	EndIf;
	
	Title = StrReplace(Title, "%DocumentsCount%", DocumentsList.Count());
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrderListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Items.DocumentsList.CurrentData.Value);
	
EndProcedure

#EndRegion
