
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("ThisIsAPredefinedItem") Then
		If Parameters.ThisIsAPredefinedItem Then
			ThisIsAPredefinedItem = Parameters.ThisIsAPredefinedItem;
		EndIf;
	EndIf;
	
	If Parameters.Property("ThisIsCustomArticle") Then
		If Parameters.ThisIsCustomArticle Then
			ThisIsCustomArticle = Parameters.ThisIsCustomArticle;
		EndIf;
	EndIf;
	
	If Parameters.Property("ThisIsObjectOfFinancialAccounting") Then
		If Parameters.ThisIsObjectOfFinancialAccounting Then
			ThisIsObjectOfFinancialAccounting = Parameters.ThisIsObjectOfFinancialAccounting;
		EndIf;
	EndIf;
	
	AllowEditingAnalytics = Not ThisIsAPredefinedItem And Not ThisIsObjectOfFinancialAccounting;
	AllowEditingMethodOfSpecifyingInvoices = False;
	
	If ThisIsObjectOfFinancialAccounting Then
		Items.EnableEdit.Visible = False;
		Items.DescriptionOfActionEditingAnalytics.Visible = False;
		Items.AllowEditingAnalytics.Visible = False;
		Items.DescriptionOfActionEditingInvoiceIndicationMethod.Visible = False;
		Items.AllowEditingMethodOfSpecifyingInvoices.Visible = False;
		Items.DescriptionOfActionFinancialAccountingObject.Visible = True;
	Else
		Items.EnableEdit.Visible = True;
		Items.DescriptionOfActionEditingAnalytics.Visible = True;
		Items.AllowEditingAnalytics.Visible = True;
		Items.DescriptionOfActionEditingInvoiceIndicationMethod.Visible = ThisIsCustomArticle;
		Items.AllowEditingMethodOfSpecifyingInvoices.Visible = ThisIsCustomArticle;
		Items.DescriptionOfActionFinancialAccountingObject.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ThisIsAPredefinedItem Then
		ShowMessageBox(Undefined, NStr("vi = 'Không thể thay đổi thuộc tính phần tử định trước!';
										|ru = 'Свойства предопределенного элемента изменять нельзя!';
										|en = 'Cannot change predefined item properties.'; fa = 'Cannot change predefined item properties.';
										|it = 'Свойства предопределенного элемента изменять нельзя!';
										|pl = 'Właściwości elementu predefiniowanego nie mogą zostać zmienione!';
										|tr = 'Önceden tanımlanmış öğenin özellikleri değiştirilmemelidir!'"));
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	
	If AllowEditingAnalytics Then
		Result.Add("AssetLiability");
		Result.Add("ValueType");
		Result.Add("Dimension");
	EndIf;
	
	If AllowEditingMethodOfSpecifyingInvoices Then
		Result.Add("LedgerAccountsInEntrySettings");
	EndIf;
	
	Close(Result);

EndProcedure

#EndRegion
