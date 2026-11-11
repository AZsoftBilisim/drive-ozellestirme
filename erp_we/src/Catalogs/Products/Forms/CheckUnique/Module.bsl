
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TableFound.Load(GetFromTempStorage(Parameters.AddressTemporaryStorageTableFound));
	Items.ContinueWrite.Visible = Parameters.ThisIsARecord
										And Users.RolesAvailable("EnterInformationAboutItemsWithoutControl")
										And TableFound.FindRows(New Structure("FoundByName", True)).Count() = 0;
										
	If TableFound.Count() > 0
		And TypeOf(TableFound[0].Ref) = Type("CatalogRef.ItemsCharacteristics") Then
		TheseAreCharacteristics = True;
	Else
		TheseAreCharacteristics = False;
	EndIf;
	
	Items.TableFoundFoundByBarcode.Visible = Not TheseAreCharacteristics;
	
	If TheseAreCharacteristics Then
		Items.TableFoundRef.Title = NStr("vi = 'Đặc tính';
										|ru = 'Характеристика';
										|en = 'Variant'; fa = 'گونه';
										|it = 'Caratteristica';
										|pl = 'Variant';
										|tr = 'Varyant'");
		Items.ExplanationFound.Title     = NStr("vi = 'Đã tìm thấy đặc tính với dữ liệu tương tự. Hãy quyết định các thao tác tiếp theo.';
												|ru = 'Найдены характеристики с аналогичными данными. Примите решение о дальнейших действиях.';
												|en = 'Variants with similar data are found. Decide on further actions.'; fa = 'Variants with similar data are found. Decide on further actions.';
												|it = 'Trovate caratteristiche con dati analoghi. Prendete una decisione sulle azioni successive.';
												|pl = 'Znaleziono cechy z pokrywającymi się danymi. Podejmij decyzję o następnych działaniach.';
												|tr = 'Benzer verilerle varyantlar bulundu. Sonraki adımlara karar ver.'");
	Else
		Items.TableFoundRef.Title = NStr("vi = 'Mặt hàng';
										|ru = 'Номенклатура';
										|en = 'Items'; fa = 'اقلام';
										|it = 'Articolo';
										|pl = 'Items';
										|tr = 'Öğe'");
		Items.ExplanationFound.Title     = NStr("vi = 'Đã tìm thấy mặt hàng với dữ liệu tương tự. Hãy quyết định các thao tác tiếp theo.';
												|ru = 'Найдена номенклатура с аналогичными данными. Примите решение о дальнейших действиях.';
												|en = 'Items with similar data are found. Decide on further actions.'; fa = 'اقلام با داده‌های مشابه یافت شدند. درباره اقدامات بعدی تصمیم بگیرید.';
												|it = 'Trovato articolo con dati uguali. Prenda decisione sulle azione successive.';
												|pl = 'Znaleziono nomenklaturę z podobnymi danymi. Zdecyduj się na dalsze działania.';
												|tr = 'Benzer verilere sahip bir öğe bulundu. Sonraki adımlar ile ilgili karar verin.'");
	EndIf;
		
EndProcedure

#EndRegion

#Region ProcessingCommands_

&AtClient
Procedure SelectAnExisting(Command)
	
	ClearMessages();
	If Items.TableFound.CurrentData = Undefined Then
		MessageText = NStr("vi = 'Mặt hàng không được chọn';
							|ru = 'Номенклатура не выбрана';
							|en = 'Items are not selected'; fa = 'Items are not selected';
							|it = 'Articolo non selezionato';
							|pl = 'Nie wybrano towaru';
							|tr = 'Öğe seçilmedi'");
		
		CommonClientServer.MessageToUser(MessageText,
		,
		"TableFound");
		Return;
	EndIf;
	
	ReturnStructure = ProductsClient.NewCompletionProcessingResult();
		
	ReturnStructure.Action = "SelectAnExisting";
	ReturnStructure.Ref = Items.TableFound.CurrentData.Ref;
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure ContinuePopulation(Command)
	
	ReturnStructure = ProductsClient.NewCompletionProcessingResult();
	
	ReturnStructure.Action = "ContinuePopulation";
	ReturnStructure.Ref = Undefined;
	Close(ReturnStructure);
	
EndProcedure

&AtClient
Procedure ContinueWrite(Command)
	
	ReturnStructure = ProductsClient.NewCompletionProcessingResult();
	
	ReturnStructure.Action = "ContinueWrite";
	ReturnStructure.Ref = Undefined;
	Close(ReturnStructure);
	
EndProcedure

#EndRegion