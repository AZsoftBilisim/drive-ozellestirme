
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Validation", 		   Record.Validation);
	Query.SetParameter("Organization", 	   Record.Organization);
	Query.SetParameter("CheckedPeriod", Record.CheckedPeriod);
	Query.SetParameter("Issue1", 		   Record.Issue1);
	
	// Filling in the list of objects.
	Query.Text =
	"SELECT
	|	ObjectsOfSystemStatusIssues.Object,
	|	ObjectsOfSystemStatusIssues.CompositeObject,
	|	ObjectsOfSystemStatusIssues.Presentation
	|FROM
	|	InformationRegister.ObjectsOfSystemStatusIssues AS ObjectsOfSystemStatusIssues
	|WHERE
	|	ObjectsOfSystemStatusIssues.Issue1 = &Issue1
	|
	|ORDER BY
	|	Object
	|AUTOORDER";
	
	Selection = Query.Execute().Select();
	ObjectsWithIssues.Clear();
	
	While Selection.Next() Do
		ObjectsWithIssues.Add(
			?(ValueIsFilled(Selection.Object), Selection.Object,
				?(ValueIsFilled(Selection.Presentation), Selection.Presentation, Selection.CompositeObject)));
	EndDo;
	
	Items.ObjectsWithIssues.Visible = (ObjectsWithIssues.Count() > 0);
	
	// Filling out the transcript.
	Details.Clear();
	
	Query.Text =
	"SELECT TOP 1
	|	SystemStatusIssues.AdditionalInformation
	|FROM
	|	InformationRegister.SystemStatusIssues AS SystemStatusIssues
	|WHERE
	|	SystemStatusIssues.Issue1 = &Issue1";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		AdditionalInformation = Selection.AdditionalInformation; // ValueStorage
		AdditionalInformation_3 = AdditionalInformation.Get();
		
		If TypeOf(AdditionalInformation_3) = Type("Structure") Or TypeOf(AdditionalInformation_3) = Type("FixedStructure") Then
			
			AllRefsType = Common.AllRefsTypeDetails();
			
			For Each KeyAndValue In AdditionalInformation_3 Do
				
				If ValueIsFilled(KeyAndValue.Value) And AllRefsType.ContainsType(TypeOf(KeyAndValue.Value)) Then
					Details.Add(KeyAndValue.Value, KeyAndValue.Key + ": " + KeyAndValue.Value);
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Items.Details.Visible = (Details.Count() > 0);
	
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

&AtClient
Procedure DetailsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, Details[RowSelected].Value);
	
EndProcedure

&AtClient
Procedure ObjectsWithIssuesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, ObjectsWithIssues[RowSelected].Value);
	
EndProcedure

#EndRegion
