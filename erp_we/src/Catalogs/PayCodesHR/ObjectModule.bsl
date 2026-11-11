

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	Query = New Query;
	QueryText = "SELECT
	|	PayCodesHR.Ref AS Ref,
	|	PayCodesHR.Presentation AS Presentation
	|FROM
	|	Catalog.PayCodesHR AS PayCodesHR
	|WHERE
	|	NOT PayCodesHR.DeletionMark
	|	AND NOT PayCodesHR.Ref = &Ref
	|	AND (NOT PayCodesHR.LetterCode = """"
	|	AND PayCodesHR.LetterCode = &LetterCode
	|	OR NOT PayCodesHR.Numeric_Code = """"
	|	AND PayCodesHR.Numeric_Code = &Numeric_Code)";
	Query.Text = QueryText;
	Query.Parameters.Insert("Ref", Ref);
	Query.Parameters.Insert("LetterCode", LetterCode);
	Query.Parameters.Insert("Numeric_Code", Numeric_Code);
	Selection = Query.Execute().Select();
	If Selection.Next() Then 
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Выбранный Буквенный или Цифровой код уже используются в виде времени %1';
																					|vi = 'The selected Letter or Numeric code is already used in the ""%1"" work time type';
																					|en = 'The selected Letter or Numeric code is already used in the ""%1"" work time type'; fa = 'The selected Letter or Numeric code is already used in the ""%1"" work time type';
																					|it = 'The selected Letter or Numeric code is already used in the ""%1"" work time type';
																					|pl = 'The selected Letter or Numeric code is already used in the ""%1"" work time type';
																					|tr = 'Seçilen Harf veya Rakam Kodu zaman türünde zaten kullanılıyor %1'"), 
		Selection.Presentation);
		Common.MessageToUser(ErrorText);
		Cancel = True;
	EndIf;

EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf
