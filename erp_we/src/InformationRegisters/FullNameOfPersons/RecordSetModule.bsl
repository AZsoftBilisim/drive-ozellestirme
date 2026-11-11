#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	For Each Record In ThisObject Do
		
		If IsBlankString(Record.Initials) Then
			Record.Initials = InitialsByFirstNamePatronymic(Record.Name, Record.MiddleName);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If Not AdditionalProperties.Property("DonTFormName") Then
		
		// Called not from the form of an individual element
		TableOfIndividuals = ThisObject.Unload();
		TableOfIndividuals.GroupBy("Individual", "");
		
		UpdateNamesOfIndividuals(TableOfIndividuals.UnloadColumn("Individual"));	
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Re-fills in the field Name of the specified individuals according to the register data.
//
Procedure UpdateNamesOfIndividuals(ArrayOfIndividuals)
	
 	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ArrayOfIndividuals", ArrayOfIndividuals);
	
	Query.Text = 
	"SELECT
	|	FullNameOfPersonsSliceLast.Individual,
	|	CAST(FullNameOfPersonsSliceLast.LastName + CASE
	|			WHEN FullNameOfPersonsSliceLast.Name = """"
	|				THEN """"
	|			ELSE "" "" + FullNameOfPersonsSliceLast.Name
	|		END + CASE
	|			WHEN FullNameOfPersonsSliceLast.MiddleName = """"
	|				THEN """"
	|			ELSE "" "" + FullNameOfPersonsSliceLast.MiddleName
	|		END AS STRING(50)) AS NewDescription
	|INTO TTIndividualNamesLast
	|FROM
	|	InformationRegister.FullNameOfPersons.SliceLast(, Individual IN (&ArrayOfIndividuals)) AS FullNameOfPersonsSliceLast
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FullNameOfIndividual.Individual,
	|	FullNameOfIndividual.NewDescription
	|FROM
	|	TTIndividualNamesLast AS FullNameOfIndividual
	|		INNER JOIN Catalog.Persons AS Persons
	|		ON FullNameOfIndividual.Individual = Persons.Ref
	|			AND FullNameOfIndividual.NewDescription <> Persons.Description";
	
	FullNameData = Query.Execute().Select();
	
	While FullNameData.Next() Do
		
		PhysicalObject = FullNameData.Individual.GetObject();
		
		Try 
			PhysicalObject.Lock();
		Except
			
			TextOfRecordException = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thay đổi tên cá nhân %1.
				|Có thể, người sử dụng khác đang chỉnh sửa dữ liệu của nhân viên';
				|ru = 'Не удалось изменить имя физического лица %1.
				|Возможно, данные сотрудника редактируются другим пользователем';
				|en = 'Cannot change person''s name %1.
				|Maybe employee''s data is being edited by another user.'; fa = 'Cannot change person''s name %1.
				|Maybe employee''s data is being edited by another user.';
				|it = 'Non è stato possibile modificare il nome della persona fisica %1.
				| Probabilmente un altro utente sta modificando i dati del dipendente';
				|pl = 'Nie można zmienić imię osoby fizycznej %1.
				|Możliwie, że dane pracownika są edytowane przez innego użytkownika';
				|tr = 'Gerçek kişi adı değiştirilemedi %1.
				|Belki de çalışan verileri başka bir kullanıcı tarafından düzenleniyor'"),
				PhysicalObject.Description);
			Raise TextOfRecordException;
			
		EndTry;
		
		PhysicalObject.Description = FullNameData.NewDescription;
		
		PhysicalObject.Write();
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function InitialsByFirstNamePatronymic(Val Name, Val MiddleName)
	
	If IsBlankString(Name) Then
		Return "";
	EndIf;
	
	Names = ComponentsOfName(Name);
	If Names.Count() > 1 Then
		Initials = Left(Names[0], 1) + ".-" + Left(Names[1], 1) + ".";
	Else
		Initials = Left(Name, 1) + ".";
	EndIf;
	
	If Not IsBlankString(MiddleName) Then
		Initials = Initials + " " + Left(MiddleName, 1) + ".";
	EndIf;
	
	Return Initials;
	
EndFunction

Function ComponentsOfName(Val Name)
	
	Names = New Array;
	
	If Not IsBlankString(Name) Then
		
		NameSeparator = "-";
		SeparatorPosition = StrFind(Name, NameSeparator);
		If SeparatorPosition = 0 Then
			NameSeparator = " ";
			SeparatorPosition = StrFind(Name, NameSeparator);
		EndIf;
		
		Names = StrSplit(Name, NameSeparator, False);
		
	EndIf;
	
	Return Names;
	
EndFunction

#EndRegion

#EndIf
