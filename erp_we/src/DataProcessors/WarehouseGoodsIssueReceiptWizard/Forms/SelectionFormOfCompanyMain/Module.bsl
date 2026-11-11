
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("CompanyArray") Then
		For Each Organization In Parameters.CompanyArray Do
			String = Object.SelectedCompanies.Add();
			String.Organization = Organization;
			String.Picture    = PictureLib.Organization;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("Array") Then
		
		For Each Organization In ValueSelected Do
			RowFilter  = New Structure("Organization", Organization);
			RowsArray = Object.SelectedCompanies.FindRows(RowFilter);
			
			If RowsArray.Count() = 0 Then
				NewRow = Object.SelectedCompanies.Add();
				NewRow.Organization = Organization;
				NewRow.Picture    = PictureLib.Organization;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OKButton(Command)
	
	CompanyArray = New Array;
	
	For Each String In Object.SelectedCompanies Do
		CompanyArray.Add(String.Organization);
	EndDo;
	
	Close(CompanyArray);
	
EndProcedure

&AtClient
Procedure CancelButton(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure SelectCompany(Command)

	OpenForm("Catalog.Companies.ChoiceForm",New Structure("ChoiceMode,MultipleChoice,CloseOnChoice",True,True,False), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectDepositor(Command)
		
	OpenForm("DataProcessor.WarehouseGoodsIssueReceiptWizard.Form.SelectDepositor", New Structure("CloseOnChoice",False), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectedCompaniesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	FormParameters = New Structure("ChoiceMode, MultipleChoice, CloseOnChoice", True, True, False);
	
	OpenForm("Catalog.Companies.ChoiceForm", FormParameters, ThisForm, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion
