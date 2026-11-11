#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion

#Region Private

#Region Other

// Creates the supplier's price nomenclature Registration document and fills it in with processing data.
//
// Parameters:
//	RegisterChangedPrices - Boolean - if True, only the changed prices are copied To the products table part.
//
// Returns:
//	DocumentRef.VendorPriceList - if the document was created successfully
//	Undefined - if the document could not be created.
//
Function CreateSupplierProductPriceRegistrationDocument(RegisterChangedPrices) Export
	
	DocumentObject = Documents.VendorPriceList.CreateDocument();
	
	DocumentObject.Date              = Date;
	DocumentObject.Partner           = Partner;
	DocumentObject.Comment       = Comment;
	DocumentObject.EmployeeResponsible     = Users.CurrentUser();
	
	ThereAreProducts_ = False;
	
	For Each CurRow In Goods Do

		If RegisterChangedPrices And CurRow.Price = CurRow.NewPrice Then
			Continue;
		EndIf;
		NewRow = DocumentObject.Goods.Add();
		FillPropertyValues(NewRow, CurRow);
		NewRow.Price = CurRow.NewPrice;
		ThereAreProducts_ = True;
		If NewRow.MinimumDeliveryLot > 0 Or ValueIsFilled(NewRow.OrderPackage) Then
			NewRow.SettingConditions = True;
		EndIf;
	EndDo;
	
	If ThereAreProducts_ Then
		Try
			DocumentObject.Write(DocumentWriteMode.Posting);
			Return DocumentObject.Ref;
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
			Return Undefined;
		EndTry;
	Else
		
		If RegisterChangedPrices = 1 Then
			
			ErrorText = NStr("vi = 'Không có đơn giá sửa đổi';
							|ru = 'Отсутствуют измененные цены';
							|en = 'Changed prices are missing'; fa = 'Changed prices are missing';
							|it = 'Non ci sono prezzi modificati';
							|pl = 'Brak zmian ceny';
							|tr = 'Değişen fiyat bulunmamaktadır'");
			CommonClientServer.MessageToUser(
				ErrorText,
				,
				,
				,);
			
		EndIf;
		
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
