#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
	ProductCostElementsLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
	ProductCostElementsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not IdentifierIsUnique() Then
		Common.MessageToUser(
		StrReplace(NStr("vi = 'Trong cơ sở dữ liệu đã có dạng tính toán với tên định danh ""%Id%"".
			|Tên định danh phải là duy nhất';
			|ru = 'В базе данных уже содержится статья калькуляции с идентификатором ""%Id%"".
			|Идентификатор должен быть уникальным';
			|en = 'Infobase already contains a product cost element with the ""%Id%"" ID. 
			|The ID should be unique'; fa = 'Infobase already contains a product cost element with the ""%Id%"" ID. 
			|The ID should be unique';
			|it = 'Nel database esiste già un articolo di calcolo con l''identificatore ""%Id%"".
			|L''identificatore deve essere univoco';
			|pl = 'W bazie danych istnieje już rodzaj kosztu z identyfikatorem ""%Id%"".
			|Identyfikator musi być unikalny';
			|tr = 'Veri tabanını zaten ""%Id%"" tanımlayıcısına sahip ürün maliyet kalemi içermektedir.
			|Tanımlayıcı benzersiz olmalıdır'"), "%Id%", IDForFormulas), 
		ThisObject, "IDForFormulas",, Cancel);
	EndIf;
	
	ProductCostElementsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	ProductCostElementsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

// Searches for an ID that matches the one filled in in the object
//
// Returns:
//	Boolean
//	True if the ID is not found, False otherwise.
//
Function IdentifierIsUnique()
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.Text = "
	|SELECT
	|	1 AS Field1
	|FROM
	|	Catalog.ProductCostElements AS ProductCostElements
	|WHERE
	|	ProductCostElements.IDForFormulas = &IDForFormulas
	|	AND ProductCostElements.Ref <> &Ref";
	
	Query.SetParameter("Ref",        Ref);
	Query.SetParameter("IDForFormulas", IDForFormulas);
	
	Return Query.Execute().IsEmpty();
	
EndFunction

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
