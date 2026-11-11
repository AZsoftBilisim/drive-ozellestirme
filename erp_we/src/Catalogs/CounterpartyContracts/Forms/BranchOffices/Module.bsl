
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object.BranchOffices_.Load(Parameters.BranchOffices_.Unload());
	Object.Organization = Parameters.Organization;
	Title = Object.Organization;
	
	AllBranches = New FixedArray(AllBranchesOfOrganization(Object.Organization));
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Ref", AllBranches));
	Items.BranchOffices_Organization.ChoiceParameters = New FixedArray(ParametersArray);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	Close(Object.BranchOffices_);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	If Object.BranchOffices_.Count() > 0 Then
		ResponseHandler1 = New CallbackDescription("CompletionOfFilling", ThisObject);
		ShowQueryBox(ResponseHandler1, NStr("vi = 'Danh sách chi nhánh sẽ bị xóa. Tiếp tục?';
											|ru = 'Список филиалов будет очищен. Продолжить?';
											|en = 'List of branch offices will be cleared. Continue?'; fa = 'List of branch offices will be cleared. Continue?';
											|it = 'L''elenco delle filiali sarà ripulito. Continuare?';
											|pl = 'Lista filii zostanie oczyszczona. Kontynuować?';
											|tr = 'Şube listesi temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		FillAtServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompletionOfFilling(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		FillAtServer();
	EndIf;

EndProcedure

&AtServer
Procedure FillAtServer()
	
	Object.BranchOffices_.Clear();
	For Each Branch_ In AllBranchesOfOrganization(Object.Organization) Do
		NewRow = Object.BranchOffices_.Add();
		NewRow.Organization = Branch_;
	EndDo;
	
EndProcedure

&AtServer
Function AllBranchesOfOrganization(Organization)
	
	Return Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Organization);
	
EndFunction

#EndRegion