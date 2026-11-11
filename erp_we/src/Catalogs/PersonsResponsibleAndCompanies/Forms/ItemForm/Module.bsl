
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Parameters.Property("AutoFill") Then
		Object.Owner						= Parameters["Owner"];
		Object.Description					= Parameters["Description"];
		Object.JobTitle					= Parameters["JobTitle"];
		Object.SignatureRight	= Parameters["SignatureRight"];
		Object.StartDate					= Parameters["StartDate"];
		Object.SignatureRightDocument			= Parameters["SignatureRightDocument"];
		Object.NumberOfSignatureRightDocument	= Parameters["NumberOfSignatureRightDocument"];
		Object.DateOfDocumentSignatureRight	= Parameters["DateOfDocumentSignatureRight"];
	EndIf;
	
	OnCreatReadAtServer();
	Items.EmployeeInCharge_.ListChoiceMode = False;
	Items.Owner.Visible = GetFunctionalOption("UseMultipleCompanies");
	
	If GetFunctionalOption("BaseVersion") Then
		Items.Individual.Title = NStr("vi = 'Nhân viên';
										|ru = 'Сотрудник';
										|en = 'Employee'; fa = 'کارمند';
										|it = 'Dipendente';
										|pl = 'Pracownik';
										|tr = 'Çalışan'");
	EndIf;
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnCreatReadAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	EstablishBasisOfSignatureRight(False);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	Notify("Write_Persons", , Object.Individual);
	Notify("Write_PersonsResponsibleAndCompanies", , Object.Ref);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure JobTitleRefOnChange(Item)
	FillOutPositionPresentation();
	NameFillSelectionList();
	
EndProcedure

&AtClient
Procedure TypeOfPersonResponsibleForTheChange(Item)
	
	Object.SignatureRight = Boolean(ResponsiblePersonKind);
	
	EstablishBasisOfSignatureRight();
	
	FormItemsManagement(ThisForm);
	
EndProcedure

&AtClient
Procedure IndividualOnChange(Item)
	If UsePayroll Then
		FillInAccordingToPersonnelDataOfIndividual();
	EndIf;
	NameFillSelectionList();
	
EndProcedure

&AtClient
Procedure EmployeeInCharge_OnChange(Item)
	
	If Not UsePayroll Then
		HowToFillSelectionList();
	EndIf;
	
EndProcedure

&AtClient
Procedure PositionWhenChanged(Item)
	
	NameFillSelectionList();
	
EndProcedure

&AtClient
Procedure SignatureRightDocumentOnChange(Item)
	
	EstablishBasisOfSignatureRight();
	
EndProcedure

&AtClient
Procedure NumberOfSignatureRightDocumentOnChange(Item)
	
	EstablishBasisOfSignatureRight();
	
EndProcedure

&AtClient
Procedure DateOfDocumentSignatureRightOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	EstablishBasisOfSignatureRight();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer()
	
	ResponsiblePersonKind = Number(Object.SignatureRight);
	
	UsePayroll = Constants.UsePayroll.Get();
	
	If UsePayroll Then
		Items.PositionLine.DropListButton = False;
	Else
		Items.PositionLine.Title = NStr("vi = 'Chức vụ';
										|ru = 'Должность';
										|en = 'Job title'; fa = 'عنوان شغلی';
										|it = 'Carica';
										|pl = 'Job title';
										|tr = 'Unvan'");
		HowToFillSelectionList();
	EndIf;
	
	NameFillSelectionList(False);
	
	FormItemsManagement(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormItemsManagement(Form)
	
	Form.Items.GroupDocumentSignatureRights.Enabled = (Form.ResponsiblePersonKind = 1);
	
EndProcedure

&AtServer
Procedure FillInAccordingToPersonnelDataOfIndividual()
EndProcedure

&AtServer
Procedure FillOutPositionPresentation()
	
	Presentation = Common.ObjectAttributeValue(Object.JobTitleRef, "Description");
	
	Object.JobTitle = Presentation;
	
EndProcedure

#Region PopulatingSelectionLists

&AtServer
Procedure HowToFillSelectionList()
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED DISTINCT
	|	PersonsResponsibleAndCompanies.JobTitle AS JobTitle
	|FROM
	|	Catalog.PersonsResponsibleAndCompanies AS PersonsResponsibleAndCompanies
	|WHERE
	|	PersonsResponsibleAndCompanies.JobTitle <> """"
	|	AND PersonsResponsibleAndCompanies.EmployeeInCharge_ = &EmployeeInCharge_
	|	AND NOT PersonsResponsibleAndCompanies.DeletionMark
	|
	|ORDER BY
	|	JobTitle";
	
	Query.SetParameter("EmployeeInCharge_", Object.EmployeeInCharge_);
	
	ArrayOfPosts = Query.Execute().Unload().UnloadColumn("JobTitle");
	Items.PositionLine.ChoiceList.LoadValues(ArrayOfPosts);
	
EndProcedure

&AtServer
Procedure NameFillSelectionList(ClearingField = True)
	
	If ClearingField Then
		Object.Description = "";
	EndIf;
	
	Items.Description.ChoiceList.Clear();
	
	If ValueIsFilled(Object.Individual) Then
		
		InitialsAndLastName = PersonsTM.IndividualShortName(Object.Individual, Object.StartDate);
		InitialsAndLastName = TrimAll(InitialsAndLastName);
		
		FullNameStructure = PersonsTM.FullName(Object.Individual, Object.StartDate);
		FullName = 
			FullNameStructure.LastName + " " 
			+ FullNameStructure.Name 
			+ ?(ValueIsFilled(FullNameStructure.MiddleName), " " + FullNameStructure.MiddleName, "");
		FullName = TrimAll(FullName);
		
		If Object.SignatureRight Then
			
			If ValueIsFilled(Object.SignatureRightBasis) Then
				PresentationLastNameFirstNamePatronymic = FullName + ", " + Object.SignatureRightBasis;
				PresentationLastNameInitials = InitialsAndLastName + ", " + Object.SignatureRightBasis;
				Items.Description.ChoiceList.Add(PresentationLastNameFirstNamePatronymic);
				If PresentationLastNameFirstNamePatronymic <> PresentationLastNameInitials Then
					Items.Description.ChoiceList.Add(PresentationLastNameInitials);
				EndIf;
				If ValueIsFilled(Object.JobTitle) Then
					PresentationLastNameFirstNamePatronymic = Object.JobTitle + " " + FullName + ", " + Object.SignatureRightBasis;
					PresentationLastNameInitials = Object.JobTitle + " " + InitialsAndLastName + ", " + Object.SignatureRightBasis;
					Items.Description.ChoiceList.Add(PresentationLastNameFirstNamePatronymic);
					If PresentationLastNameFirstNamePatronymic <> PresentationLastNameInitials Then
						Items.Description.ChoiceList.Add(PresentationLastNameInitials);
					EndIf;
				EndIf;
			EndIf;
		Else
			PresentationLastNameFirstNamePatronymic = TrimAll(Object.JobTitle + " " + FullName);
			If FullName <> PresentationLastNameFirstNamePatronymic Then
				Items.Description.ChoiceList.Add(PresentationLastNameFirstNamePatronymic);
			EndIf;	
			
			PresentationLastNameInitials = TrimAll(Object.JobTitle + " " + InitialsAndLastName);
			If PresentationLastNameFirstNamePatronymic <> PresentationLastNameInitials Then
				Items.Description.ChoiceList.Add(PresentationLastNameInitials);
			EndIf;
		EndIf;
		
		Items.Description.ChoiceList.Add(FullName);
		
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure EstablishBasisOfSignatureRight(ClearName = True)
	
	If Object.SignatureRight And Not IsBlankString(Object.SignatureRightDocument) Then
		Object.SignatureRightBasis =
			Object.SignatureRightDocument 
			+ ?(IsBlankString(Object.NumberOfSignatureRightDocument), "", " № " + Object.NumberOfSignatureRightDocument)
			+ ?(Not ValueIsFilled(Object.DateOfDocumentSignatureRight),  "", " " + NStr("vi = 'ngày';
																						|ru = 'от';
																						|en = 'dated'; fa = 'مورخ';
																						|it = 'del';
																						|pl = 'dated';
																						|tr = 'tarih'") + " " + Format(Object.DateOfDocumentSignatureRight, "DLF=D") + " " + NStr("vi = './.';
																																													|ru = 'г.';
																																													|en = 'year'; fa = 'سال';
																																													|it = 'anno';
																																													|pl = 'year';
																																													|tr = 'yıl'"));
	Else
		Object.SignatureRightBasis = "";
	EndIf;
	
	NameFillSelectionList(ClearName);
	
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
	If Item.Name = "sh_ShamsiInput_DateOfDocumentSignatureRight" Then
		DateOfDocumentSignatureRightOnChange(Items.DateOfDocumentSignatureRight);
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
