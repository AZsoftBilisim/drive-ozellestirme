#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// ERP Start
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	// ERP End
	
	For Each Record In ThisObject Do
		Record.Presentation = InformationRegisters.DocumentsPersons.RecordPresentation(Record);
	EndDo;
	
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// ERP Start
	
	If DataExchange.Load Then
		Return;
	EndIf;
	// ERP End
	
	CheckIdentityDocuments(Cancel, Replacing);
	
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	
EndProcedure

#EndRegion

#Region Private

Procedure CheckIdentityDocuments(Cancel, Replacing)
	
	
	Query = New Query;
	Query.SetParameter("DocumentsTable",	Unload(, "Person, Period, ThisIsAnIdentityDocument"));
	
	Query.Text =
	"SELECT
	|	DocumentsTable.Person AS Person,
	|	DocumentsTable.Period AS Period
	|INTO TT_Documents
	|FROM
	|	&DocumentsTable AS DocumentsTable
	|WHERE
	|	DocumentsTable.ThisIsAnIdentityDocument
	|
	|INDEX BY
	|	Person,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsPersons.Person AS Person,
	|	DocumentsPersons.Period AS Period,
	|	COUNT(DocumentsPersons.Person) AS DocumentsCount
	|FROM
	|	InformationRegister.DocumentsPersons AS DocumentsPersons
	|		INNER JOIN TT_Documents AS DocumentsSlice
	|		ON DocumentsPersons.Period = DocumentsSlice.Period
	|			AND DocumentsPersons.Person = DocumentsSlice.Person
	|			AND (DocumentsPersons.ThisIsAnIdentityDocument)
	|
	|GROUP BY
	|	DocumentsPersons.Person,
	|	DocumentsPersons.Period
	|
	|HAVING
	|	COUNT(DocumentsPersons.Person) > 1";
	Selection = Query.Execute().Select();
	
	MessageText = NStr("vi = 'Tính đến %1 đã nhập giấy tờ cá nhân của cá nhân %2.';
						|ru = 'На %1 у физлица %2 уже введен документ, удостоверяющий личность.';
						|en = 'ID document of person %2 has been already entered as of %1.'; fa = 'ID document of person %2 has been already entered as of %1.';
						|it = 'Alla data del %1 è stato già inserito il documento di identità della persona fisica%2.';
						|pl = 'Dokument tożsamości został już wprowadzony dla %1 osoby fizycznej %2.';
						|tr = '%1''da, %2 gerçek kişinin artık girilmiş bir kimlik belgesi var.'");
	
	While Selection.Next() Do
		Cancel = True;
		
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(MessageText, Format(Selection.Period, "DLF=D"), Selection.Person));
	EndDo;
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf