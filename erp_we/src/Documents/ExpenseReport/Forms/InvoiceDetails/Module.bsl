
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Number           = Parameters.InvoiceNumber;
	Date            = Parameters.InvoiceDate;
	Organization     = Parameters.Organization;
	Counterparty      = Parameters.Counterparty;
	TaxInvoice     = Parameters.TaxInvoice;
	RowSelected = Parameters.RowSelected;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NumberOnChange(Item)
	
	TaxInvoice = Undefined;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	TaxInvoice = Undefined;
	
EndProcedure

&AtClient
Procedure TaxInvoiceOnChange(Item)
	
	If ValueIsFilled(TaxInvoice) Then
		InvoiceWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure InvoiceWhenChangedOnServer()
	
	FillPropertyValues(ThisObject, Common.ObjectAttributesValues(TaxInvoice, "Number, Date"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	InvoiceDetails = New Structure;
	InvoiceDetails.Insert("InvoiceNumber", Number);
	InvoiceDetails.Insert("InvoiceDate", Date);
	InvoiceDetails.Insert("TaxInvoice", TaxInvoice);
	InvoiceDetails.Insert("RowSelected", RowSelected);
	
	Close(InvoiceDetails);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Modified = False;
	Close();
	
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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
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
