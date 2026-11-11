
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Var ListOfFieldsToDecrypt;
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Record.SourceRecordKey.IsEmpty() Then
		Cancel = True;
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Validation", 		   Record.Validation);
	Query.SetParameter("Organization", 	   Record.Organization);
	Query.SetParameter("CheckedPeriod", Record.CheckedPeriod);
	Query.SetParameter("Issue1", 		   Record.Issue1);
	Query.SetParameter("CompositeObject",   Record.CompositeObject);
	
	// Filling in the problem view.
	If ValueIsFilled(Record.Presentation) Then
		
		IssuePresentation = Record.Presentation;
		
	Else
		
		Query.Text =
		"SELECT TOP 1
		|	SystemStatusIssues.Presentation
		|FROM
		|	InformationRegister.SystemStatusIssues AS SystemStatusIssues
		|WHERE
		|	SystemStatusIssues.Issue1 = &Issue1";
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			IssuePresentation = Selection.Presentation;
		Else
			IssuePresentation = NStr("vi = 'không thể tìm thấy một mô tả của vấn đề';
									|ru = 'не удалось нийти описание проблемы';
									|en = 'cannot find issue description'; fa = 'cannot find issue description';
									|it = 'non è stato possibile trovare una descrizione del problema';
									|pl = 'nie można znaleźć opisu problemu';
									|tr = 'sorunun ayrıntıları bulamadı'");
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(Record.Object) Then
		
		Items.Object.Visible = True;
		Items.Details.Visible = False;
		Items.RegisterPresentationForDecryption.Visible = False;
		
	Else
		
		Items.Object.Visible = False;
		Items.Details.Visible = True;
		
		// Filling out the transcript.
		Details.Clear();
		
		Query.Text =
		"SELECT TOP 1
		|	ObjectsOfSystemStatusIssues.CheckedPeriod AS Period,
		|	ObjectsOfSystemStatusIssues.CompositeObjectDrillDown
		|FROM
		|	InformationRegister.ObjectsOfSystemStatusIssues AS ObjectsOfSystemStatusIssues
		|WHERE
		|	ObjectsOfSystemStatusIssues.Issue1 = &Issue1
		|	AND ObjectsOfSystemStatusIssues.CompositeObject = &CompositeObject";
		
		Selection = Query.Execute().Select();
		
		ExplanationFormParameters = New Structure;
		
		If Selection.Next() Then
			
			ExplanationFormParameters.Insert(MonthEndTransactionsClientServer.NameOfServicePropertyOfFormsToOpen(), True);
			ExplanationFormParameters.Insert("FilterToDecrypt", New Structure);
			ExplanationFormParameters.FilterToDecrypt.Insert("Period", Selection.Period);
			
			CompositeObjectDrillDown = Selection.CompositeObjectDrillDown; // ValueStorage
			AdditionalInformation_3 = CompositeObjectDrillDown.Get();
			
			If TypeOf(AdditionalInformation_3) = Type("Structure") Or TypeOf(AdditionalInformation_3) = Type("FixedStructure") Then
				
				AllRefsType = Common.AllRefsTypeDetails();
				
				AdditionalInformation_3.Property("ListOfFieldsToDecrypt", ListOfFieldsToDecrypt);
				
				For Each KeyAndValue In AdditionalInformation_3 Do
					
					If KeyAndValue.Key = "RegisterNameToDecrypt" Then
						
						RegisterMetadataForDecryption = Metadata.FindByFullName(KeyAndValue.Value);
						
						If RegisterMetadataForDecryption <> Undefined Then
							
							RegisterNameToDecrypt = KeyAndValue.Value;
							
							RegisterPresentationForDecryption = StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Mở biểu mẫu danh sách đăng ký ""%1"".';
									|ru = 'Открыть форму списка регистра ""%1"".';
									|en = 'Open list form of the ""%1"" register.'; fa = 'Open list form of the ""%1"" register.';
									|it = 'Aprire il form dell''elenco del registro ""%1"".';
									|pl = 'Otwórz formularz listy rejestru ""%1"".';
									|tr = '""%1"" kayıt listesi formunu aç.'"),
								RegisterMetadataForDecryption.Synonym);
							
						EndIf;
							
					ElsIf KeyAndValue.Key = "ListOfFieldsToDecrypt" Then
						// skip it
					Else
						
						If AllRefsType.ContainsType(TypeOf(KeyAndValue.Value)) Then
							
							If ValueIsFilled(KeyAndValue.Value) Then 
								
								FieldPresentation = KeyAndValue.Key;
								
								If ListOfFieldsToDecrypt <> Undefined Then
									
									FieldDetails = ListOfFieldsToDecrypt.FindByValue(KeyAndValue.Key);
									If FieldDetails <> Undefined And ValueIsFilled(FieldDetails.Presentation) Then
										FieldPresentation = FieldDetails.Presentation;
									EndIf;
									
								EndIf;
								
								Details.Add(KeyAndValue.Value, FieldPresentation + ": " + KeyAndValue.Value);
								
							EndIf;
							
							ExplanationFormParameters.FilterToDecrypt.Insert(KeyAndValue.Key, KeyAndValue.Value);
							
						EndIf;
						
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
		ExplanationFormParameters.Insert("FilterToDecrypt", New FixedStructure(ExplanationFormParameters.FilterToDecrypt));
		ExplanationFormParameters = New FixedStructure(ExplanationFormParameters);
		
	EndIf;
	
	Items.RegisterPresentationForDecryption.Visible = ValueIsFilled(RegisterPresentationForDecryption);
	
	// Getting the date of the last check.
	Query.Text =
	"SELECT TOP 1
	|	MonthEndChecklistsStatus.ExecutionDate
	|FROM
	|	InformationRegister.MonthEndChecklistsStatus AS MonthEndChecklistsStatus
	|WHERE
	|	MonthEndChecklistsStatus.Validation = &Validation
	|	AND MonthEndChecklistsStatus.Organization = &Organization
	|	AND MonthEndChecklistsStatus.CheckedPeriod = &CheckedPeriod";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		CheckDate = Format(Selection.ExecutionDate, "DLF=DT");
	Else
		CheckDate = NStr("vi = 'không thể xác định ngày kiểm tra';
						|ru = 'не удалось определить дату проверки';
						|en = 'cannot determine the check date'; fa = 'cannot determine the check date';
						|it = 'non è stato possibile determinare la data della correzione';
						|pl = 'nie udało się ustalić daty weryfikacji';
						|tr = 'kontrol tarihi belirlenemedi'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DetailsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, Details[RowSelected].Value);
	
EndProcedure

&AtClient
Procedure RegisterPresentationForDecryptionClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm(RegisterNameToDecrypt + ".ListForm", New Structure(ExplanationFormParameters));
	
EndProcedure

#EndRegion
