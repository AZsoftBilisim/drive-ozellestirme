#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If Not GetFunctionalOption("UseMultiCountryAccounting") And IsNewRecord() Then
		For Each Record In ThisObject Do
			Record.Country = SettingsValueClientServerCached.MainCountry();
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each Record In ThisObject Do
		If Record.ExcisableGoods
			And Not ValueIsFilled(Record.ExcisableGoodsCategory)
			And Not GetFunctionalOption("BaseVersion") Then
				
				RecordStructure = New Structure("Period,Products,Country");
				FillPropertyValues(RecordStructure, Record);
				
				RecordKey = InformationRegisters.ExcisableGoodsCategories.CreateRecordKey(RecordStructure);
				
				FieldName = NStr("vi = 'Thể loại';
								|ru = 'Категория';
								|en = 'Category'; fa = 'دسته';
								|it = 'Category';
								|pl = 'Category';
								|tr = 'Kategori'");
				MessageText = CommonClientServer.FillingErrorText( , , FieldName);
				Common.MessageToUser(
					MessageText, RecordKey, "Record.ExcisableGoodsCategory", , Cancel);
		EndIf;
	EndDo;

EndProcedure

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") And IsNewRecord() Then
		Constants.MainCountry.CheckFilling();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function IsNewRecord()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ExcisableGoodsCategories.Period AS Period
		|FROM
		|	InformationRegister.ExcisableGoodsCategories AS ExcisableGoodsCategories
		|WHERE
		|	ExcisableGoodsCategories.Period IN(&Period)
		|	AND ExcisableGoodsCategories.Products IN(&Products)
		|	AND ExcisableGoodsCategories.Country IN(&Country)";
	
	Query.SetParameter("Products", UnloadColumn("Products"));
	Query.SetParameter("Period", UnloadColumn("Period"));
	Query.SetParameter("Country", UnloadColumn("Country"));
	
	QueryResult = Query.Execute();
	
	Return QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#EndIf