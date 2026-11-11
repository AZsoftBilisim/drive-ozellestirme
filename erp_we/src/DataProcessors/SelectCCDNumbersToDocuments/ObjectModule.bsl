#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("Code");
	
	If Not ValueIsFilled(Code)
		And CCDNumberType <> Enums.CCDNumberTypes.KitRNPT Then
		
		FieldPresentation = ?(CCDNumberType = Enums.CCDNumberTypes.CCDNumber,
								NStr("vi = 'Số tờ khai hải quan';
									|ru = 'Номер таможенной декларации';
									|en = 'Customs declaration number'; fa = 'شماره اظهارنامه گمرکی';
									|it = 'Numero della dichiarazione doganale';
									|pl = 'Numer deklaracji celnej';
									|tr = 'Gümrük beyanname numarası'"),
								NStr("vi = 'Số đăng ký lô hàng';
									|ru = 'Номер РНПТ';
									|en = 'RNPT'; fa = 'RNPT';
									|it = 'Numero di registrazione lotti prodotti';
									|pl = 'Numer rejestracyjny partii towaru';
									|tr = 'RNPT numarası'"));
		
		ErrorText = NStr("vi = 'Chưa điền trường ""%1"".';
						|ru = 'Поле ""%1"" не заполнено.';
						|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
						|it = 'Il campo ""%1"" non è compilato.';
						|pl = 'Nie wypełniono pola ""%1"".';
						|tr = '""%1"" alanı doldurulmadı.'");
		ErrorText = StrTemplate(ErrorText, FieldPresentation);
		
		Common.MessageToUser(ErrorText, , "Code", , Cancel);
		
	EndIf;
	
	If CCDNumberType <> Enums.CCDNumberTypes.ProductBatchIDNumber Then
		AttributesNotToCheck.Add("UnitOfMeasure");
	EndIf;
	
	FillInUnverifiableAttributesOfRNPTKit(AttributesNotToCheck);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	CheckForDuplicatesOfElement(Cancel);
	CheckFillingOfTraceableComponents(Cancel);
	CheckCorrectnessOfCostIndication(Cancel)
	
EndProcedure

#EndRegion

#Region Private

#Region CheckingObjectFilling

Procedure FillInUnverifiableAttributesOfRNPTKit(AttributesNotToCheck)
	
	If CCDNumberType = Enums.CCDNumberTypes.KitRNPT
		And AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1, 1, 1)) Then
		
		Return;
		
	EndIf;
	
	AttributesNotToCheck.Add("TraceableComponents");
	AttributesNotToCheck.Add("TraceableComponents.Code");
	AttributesNotToCheck.Add("TraceableComponents.QuantityByRNPTInADocument");
	AttributesNotToCheck.Add("TraceableComponents.QuantityByGBRN");
	AttributesNotToCheck.Add("TraceableComponents.FEACNUnitOfMeasure");
	
EndProcedure

// Checks the presence of duplicates in the information base for elements of the type 'NomerRNPT' or 'NomerGTD'.
//
// Parameters:
//	Cancel - Boolean - indicates whether to continue processing the Catalog item after processing the fill check.
//					If the value is True, then the object processing will be terminated.
//
Procedure CheckForDuplicatesOfElement(Cancel)
	
	If Cancel
		Or CCDNumberType = Enums.CCDNumberTypes.KitRNPT Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CCDNumbers.Ref AS Ref
	|FROM
	|	Catalog.CCDNumbers AS CCDNumbers
	|WHERE
	|	NOT CCDNumbers.DeletionMark
	|	AND CCDNumbers.Code = &Code
	|	AND CCDNumbers.OriginCountry = &OriginCountry
	|	AND CCDNumbers.CCDNumberType = &CCDNumberType
	|	AND (CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.CCDNumber)
	|		OR CCDNumbers.CCDNumberType = VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber)
	|			AND CCDNumbers.AmountByProductBatchID = &AmountByProductBatchID)";
	
	Query.SetParameter("CCDNumberType",			CCDNumberType);
	Query.SetParameter("Code",					Code);
	Query.SetParameter("OriginCountry",	OriginCountry);
	Query.SetParameter("AmountByProductBatchID",			AmountByProductBatchID);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	If Selection.Next() Then
		TypePresentation = ?(CCDNumberType = Enums.CCDNumberTypes.CCDNumber,
								NStr("vi = 'số tờ khai hải quan';
									|ru = 'номер ГТД';
									|en = 'CCD number'; fa = 'شماره اظهارنامه گمرکی (CCD)';
									|it = 'numero della polizza doganale di carico';
									|pl = 'numer ładunkowej deklaracji celnej';
									|tr = 'Gümrük Kargo Beyannamesi numarası'"),
								NStr("vi = 'số đăng ký lô hàng';
									|ru = 'номер РНПТ';
									|en = 'RNPT'; fa = 'RNPT';
									|it = 'numero di registrazione lotti prodotti';
									|pl = 'Numer rejestracyjny partii towaru';
									|tr = 'RNPT numarası'"));
		
		MessageText = NStr("vi = 'Đã tồn tại %1 tương tự: %2';
							|ru = 'Аналогичный %1 уже существует: %2';
							|en = 'Similar %1 already exists: %2'; fa = 'Similar %1 already exists: %2';
							|it = '%1 analogo esiste già: %2';
							|pl = 'Analogiczny %1 już istnieje: %2';
							|tr = 'Benzer %1zaten mevcut: %2'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
																				TypePresentation,
																				Selection.Ref);
		
		Common.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
EndProcedure

Procedure CheckFillingOfTraceableComponents(Cancel)
	
	If Cancel
		Or CCDNumberType <> Enums.CCDNumberTypes.KitRNPT Then
		
		Return;
		
	EndIf;
	
	If TraceableComponents.Count() = 0 Then
		ErrorText	= NStr("vi = 'Số đăng ký lô hàng của bộ sản phẩm cần chứa thông tin ít nhất về một thành phần chi tiết có nguồn gốc xuất xứ.
							|Hãy bổ sung thông tin vào phần bảng ""Thành phần chi tiết có nguồn gốc xuất xứ"" hoặc thay đổi kiểu phần tử danh mục.';
							|ru = 'РНПТ комплекта должен содержать информацию хотя бы об одной прослеживаемой комплектующей.
							|Дополните информацию в табличной части ""Прослеживаемые комплектующие"" или измените тип элемента справочника.';
							|en = 'The kit RNPT must contain information about at least one traceable component.
							|Supplement the information in the ""Traceable components"" table or change the catalog item type.'; fa = 'The kit RNPT must contain information about at least one traceable component.
							|Supplement the information in the ""Traceable components"" table or change the catalog item type.';
							|it = 'РНПТ комплекта должен содержать информацию хотя бы об одной прослеживаемой комплектующей.
							|Дополните информацию в табличной части ""Прослеживаемые комплектующие"" или измените тип элемента справочника.';
							|pl = 'The kit RNPT must contain information about at least one traceable component.
							|Supplement the information in the ""Traceable components"" table or change the catalog item type.';
							|tr = 'RNPT seti en az bir izlenebilir bileşen hakkında bilgi içermelidir.
							|""İzlenebilir bileşenler"" tablosundaki bilgileri tamamla veya katalog öğesinin türünü değiştir.'");
		Field		= CommonClientServer.PathToTabularSection("TraceableComponents",
																		0,
																		"ProductBatchIDNumber");
		
		Common.MessageToUser(ErrorText, , "TraceableComponents", , Cancel);
		
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Components.LineNumber			AS LineNumber,
	|	Components.ProductBatchIDNumber				AS ProductBatchIDNumber,
	|	Components.QuantityByGBRN		AS QuantityByRNPTInADocument,
	|	Components.QuantityByGBRN		AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure	AS UnitOfMeasure
	|INTO Components
	|FROM
	|	&Components AS Components
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Components.LineNumber)	AS LineNumber,
	|	Components.ProductBatchIDNumber				AS ProductBatchIDNumber,
	|	Components.UnitOfMeasure		AS UnitOfMeasure
	|FROM
	|	Components AS Components
	|
	|WHERE
	|	Components.QuantityByGBRN <> 0
	|	AND Components.QuantityByRNPTInADocument <> 0
	|	AND Components.ProductBatchIDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND Components.UnitOfMeasure <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|
	|GROUP BY
	|	Components.ProductBatchIDNumber,
	|	Components.UnitOfMeasure
	|
	|HAVING
	|	COUNT(*) > 1";
	
	Query.SetParameter("Components", TraceableComponents.Unload());
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	ErrorTextTemplate = NStr("vi = 'Số đăng ký lô hàng ""%1"" với đơn vị tính ""%2"" bị lặp lại.';
							|ru = 'Номер РНПТ ""%1"" с единицей измерения ""%2"" повторяется.';
							|en = 'RNPT ""%1"" with unit of measure ""%2"" is repeated.'; fa = 'RNPT ""%1"" with unit of measure ""%2"" is repeated.';
							|it = 'Il numero di registrazione lotti prodotti ""%1"" con unità di misura ""%2"" si ripete.';
							|pl = 'Numer rejestracyjny partii towaru ""%1"" z jednostką miary ""%2"" powtarza się.';
							|tr = '""%2"" ölçü birimiyle ""%1"" RNPT numarası tekrarlanıyor.'");
	
	While Selection.Next() Do
		ErrorText	= StrTemplate(ErrorTextTemplate,
								TrimAll(String(Selection.ProductBatchIDNumber)),
								TrimAll(String(Selection.UnitOfMeasure)));
		Field		= CommonClientServer.PathToTabularSection("TraceableComponents",
																		Selection.LineNumber,
																		"ProductBatchIDNumber");
		
		Common.MessageToUser(ErrorText, , Field, , Cancel);
	EndDo;
	
EndProcedure

Procedure CheckCorrectnessOfCostIndication(Cancel)
	
	If Cancel
		Or CCDNumberType <> Enums.CCDNumberTypes.KitRNPT Then
		
		Return;
		
	EndIf;
	
	If TraceableComponents.Total("AmountByProductBatchID") > AmountByProductBatchID Then
		MessageText = NStr("vi = 'Đã chỉ ra sai các chỉ số giá trị. Giá trị các thành phần chi tiết vượt quá giá trị bộ.';
							|ru = 'Некорректно указаны стоимостные показатели. Стоимость компклектующих превышает стоимость комплекта.';
							|en = 'The cost is incorrect. The cost of components is greater than the kit cost.'; fa = 'The cost is incorrect. The cost of components is greater than the kit cost.';
							|it = 'Некорректно указаны стоимостные показатели. Стоимость компклектующих превышает стоимость комплекта.';
							|pl = 'The cost is incorrect. The cost of components is greater than the kit cost.';
							|tr = 'Maliyet rakamları yanlış belirtilmiştir. Bileşenlerin maliyeti setin maliyetini aşmaktadır.'");
		
		Common.MessageToUser(MessageText, , "AmountByProductBatchID", "Object", Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
