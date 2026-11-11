#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Returns a serialized XML structure for selecting report rows.
//
// Parameters:
//  Warehouse		 - CatalogRef.Warehouses	 - warehouse.
//  OperationKind	 - String	 - type of operation.
//  Recommendation - String	 - recommendation.
// 
// Returns:
//  String - structure in the form of an XML string.
//
Function OrderSelectionStructureXMLString(Warehouse, OperationKind, Recommendation) Export
	
	Structure = New Structure("Warehouse, OperationKind, Recommendation", Warehouse, OperationKind, Recommendation);
	Return Common.ValueToXMLString(Structure);
	
EndFunction

// Returns a structure with recommendations.
//
// Parameters:
//  Recommendation - String	 - name of the recommendation that will be set to True.
// 
// Returns:
//  Structure - structure with field values See PresentationOfRecommendations.
//
Function StructureOfRecommendations(Recommendation) Export
	
	StructureOfRecommendations = New Structure;
	Map = PresentationOfRecommendations();
	For Each MapItem In Map Do
		StructureOfRecommendations.Insert(MapItem.Key, MapItem.Value = Recommendation);
	EndDo;
	Return StructureOfRecommendations;
	
EndFunction

// Returns views of recommendations.
// 
// Returns:
//  Map - the compliance key contains the name of the recommendation, the compliance value contains the text of the recommendation.
//
Function PresentationOfRecommendations() Export
	
	ComplianceWithRecommendations = New Map;
	ComplianceWithRecommendations.Insert("CreateGoodsIssueNotes", NStr("vi = 'Tạo phiếu xuất kho';
																		|ru = 'Завершите оформление расходных ордеров на товары';
																		|en = 'Finish creating goods issues'; fa = 'تکمیل ایجاد صدور کالا';
																		|it = 'Completa la formalizzazione dei mandati di pagamento per le merci';
																		|pl = 'Dokończ składanie zleceń wydatków na wiersze pozycji';
																		|tr = 'Ambar çıkış fişlerini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterReturnOfGoodsFromCustomer", NStr("vi = 'Hãy lập chứng từ nhận hàng bán bị trả lại';
																					|ru = 'Оформите возврат товаров от клиента';
																					|en = 'Register sales return'; fa = 'ثبت مرجوعی فروش';
																					|it = 'Completa il reso della merce dal cliente';
																					|pl = 'Sporządź wniosek o zwrot towarów od klienta';
																					|tr = 'Müşteriden ürün iadesini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterGoodsReceiptNotes", NStr("vi = 'Hãy lập phiếu nhập kho';
																			|ru = 'Оформите приходные ордера на товары';
																			|en = 'Register goods receipts'; fa = 'ثبت دریافت‌های کالا';
																			|it = 'Formalizza i reversali d''incasso per le merci';
																			|pl = 'Sporządź asygnaty przychodowe na wiersze pozycji';
																			|tr = 'Ambar giriş fişlerini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterPurchaseOfGoodsAndServices", NStr("vi = 'Hãy lập chứng từ mua hàng hóa và dịch vụ';
																					|ru = 'Оформите приобретение товаров и услуг';
																					|en = 'Register vendor invoice'; fa = 'ثبت فاکتور فروشنده';
																					|it = 'Formalizza l''acquisizione delle merci e dei servizi';
																					|pl = 'Sporządź nabycie towarów i usług';
																					|tr = 'Satın alma faturasını düzenleyin'"));
	ComplianceWithRecommendations.Insert("ProcessReceiptOfGoods", NStr("vi = 'Hãy lập chứng từ tiếp nhận hàng hóa';
																		|ru = 'Оформите поступление товаров';
																		|en = 'Register goods receipt'; fa = 'ثبت دریافت کالا';
																		|it = 'Formalizza l''arrivo della merce';
																		|pl = 'Sporządź wpływ towarów';
																		|tr = 'İrsaliye düzenle'"));
	ComplianceWithRecommendations.Insert("MakeMovementOfGoodsWithStatusAccepted", NStr("vi = 'Hãy lập chứng từ điều chuyển hàng hóa nội bộ với trạng thái ""Đã tiếp nhận""';
																						|ru = 'Оформите перемещение товаров в статусе ""Принято""';
																						|en = 'Register goods transfer in status ""Received""'; fa = 'ثبت انتقال کالا در وضعیت «دریافت‌شده»';
																						|it = 'Formalizza il trasferimento delle merci con lo stato ""Accettato""';
																						|pl = 'Sporządź przemieszczenie towarów w statusie ""Przyjęto""';
																						|tr = 'Mal transferini ""Kabul Edildi"" durumunda düzenle'"));
	ComplianceWithRecommendations.Insert("IssueBuildDocumentWithAssembledDisassembledStatus", NStr("vi = 'Hãy lập chứng từ đóng bộ với trạng thái ""Đã đóng bộ (tách bộ)""';
																									|ru = 'Оформите документ сборки в статусе ""Собрано (разобрано)""';
																									|en = 'Register kitting document in status ""Completed""'; fa = 'ثبت سند کیت‌سازی در وضعیت «تکمیل‌شده»';
																									|it = 'Emettere il documento di assemblaggio nello stato ""Assemblato (disassemblato)""';
																									|pl = 'Sporządź dokument montażu w statusie ""Zmontowane (rozmontowane)""';
																									|tr = '""Montaj yapıldı (demontaj yapıldı)"" durumunda montaj belgesini düzenle'"));
	ComplianceWithRecommendations.Insert("IssueDisassemblyDocumentWithAssembledDisassembledStatus", NStr("vi = 'Hãy lập chứng từ tách bộ với trạng thái ""Đã đóng bộ (tách bộ)""';
																										|ru = 'Оформите документ разборки в статусе ""Собрано (разобрано)""';
																										|en = 'Register reverse kitting document in status ""Completed""'; fa = 'ثبت سند کیت‌گشایی در وضعیت «تکمیل‌شده»';
																										|it = 'Emettere il documento di disassemblaggio nello stato ""assemblato (smontato)""';
																										|pl = 'Sporządź dokument demontażu w statusie ""Zmontowane (rozmontowane)""';
																										|tr = '""Montaj yapıldı (demontaj yapıldı)"" durumunda bir demontaj belgesi düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterOtherGoodsRecordingAsReceived", NStr("vi = 'Điều chỉnh nhập hàng hóa khác';
																						|ru = 'Скорректируйте прочее оприходование товаров';
																						|en = 'Adjust other receipt of goods'; fa = 'Adjust other receipt of goods';
																						|it = 'Correggere altra registrazione in contabilità delle merci';
																						|pl = 'Dostosuj inne delegowanie towarów';
																						|tr = 'Diğer mal girişini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterWarehouseActsToRecordSurpluses", NStr("vi = 'Hãy lập biên bản kho để phản ánh hàng thừa';
																						|ru = 'Оформите складские акты для отражения излишков';
																						|en = 'Register inventory adjustments to record surpluses'; fa = 'ثبت تعدیلات موجودی برای ثبت مازادها';
																						|it = 'Formalizza gli atti di magazzino per visualizzare le eccedenze';
																						|pl = 'Sporządź protokoły magazynowe w celu odzwierciedlenia nadwyżek';
																						|tr = 'Fazlalıkları yansıtma için stok düzeltmelerini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterWarehouseActsToRecordShortages", NStr("vi = 'Hãy lập biên bản kho để phản ánh hàng thiếu';
																						|ru = 'Оформите складские акты для отражения недостач';
																						|en = 'Register inventory adjustments to record shortages'; fa = 'ثبت تعدیلات موجودی برای ثبت کسری‌ها';
																						|it = 'Formalizza gli atti di magazzino per visualizzare gli ammanchi';
																						|pl = 'Sporządź protokoły magazynowe w celu odzwierciedlenia niedoborów';
																						|tr = 'Eksiklikleri yansıtma için stok düzeltmelerini düzenle'"));
	ComplianceWithRecommendations.Insert("SubmitMaterialsForProductionWithAcceptedStatus", NStr("vi = 'Hãy lập chứng từ chuyển giao nguyên vật liệu vào sản xuất với trạng thái ""Đã tiếp nhận""';
																								|ru = 'Оформите передачу материалов в производство в статусе ""Принято""';
																								|en = 'Register material transfer to production in status ""Received""'; fa = 'ثبت انتقال مواد به تولید در وضعیت «دریافت‌شده»';
																								|it = 'Formalizza il trasferimento dei materiali nella produzione con lo stato ""Accettato""';
																								|pl = 'Sporządź przekazanie materiałów do produkcji w statusie ""Przyjęto""';
																								|tr = 'Malzemelerin üretime transferini ""Kabul edildi"" durumunda düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterMaterialReturnFromProduction", NStr("vi = 'Hãy lập chứng từ thu hồi nguyên liệu từ sản xuất';
																						|ru = 'Оформите возврат материалов из производства';
																						|en = 'Register material return from production'; fa = 'ثبت مرجوعی مواد از تولید';
																						|it = 'Formalizza il reso dei materiali dalla produzione';
																						|pl = 'Sporządź zwrot materiałów z produkcji';
																						|tr = 'Malzemelerin üretimden iadesini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterProductRelease", NStr("vi = 'Hãy lập chứng từ xuất xưởng thành phẩm';
																		|ru = 'Оформите выпуск продукции';
																		|en = 'Register product release'; fa = 'ثبت خروجی محصول';
																		|it = 'Formalizza la fabbricazione dei prodotti';
																		|pl = 'Sporządź wyprodukowanie';
																		|tr = 'Ürün sürümünü düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterRawMaterialReturnFromToller", NStr("vi = 'Hãy lập chứng từ trả lại nguyên liệu từ gia công';
																					|ru = 'Оформите возврат сырья от переработчика';
																					|en = 'Register ""Goods return — Subcontracting services received""'; fa = 'ثبت «مرجوعی کالا — خدمات پیمانکاری فرعی دریافتی»';
																					|it = 'Formalizza il reso delle materie prime dal subfornitore';
																					|pl = 'Sporządź zwrot surowców od przetwórcy';
																					|tr = 'Fason üretici hammadde iadesini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterReceiptFromToller", NStr("vi = 'Hãy lập chứng từ tiếp nhận từ gia công';
																			|ru = 'Оформите поступление от переработчика';
																			|en = 'Register ""Goods receipt — External subcontracting""'; fa = 'ثبت «دریافت کالا — پیمانکاری فرعی خارجی»';
																			|it = 'Formalizza l''arrivo dal subfornitore';
																			|pl = 'Sporządź wpływy od przetwórców';
																			|tr = 'Fason üreticiden gelen ürünleri teslim alma belgesi düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterReceiptOfRawMaterialsFromMaterialProvider", NStr("vi = 'Hãy lập chứng từ tiếp nhận nguyên liệu từ người đặt gia công';
																									|ru = 'Оформите поступление сырья от давальца';
																									|en = 'Register ""Goods receipt — Subcontracting services delivered""'; fa = 'ثبت «دریافت کالا — خدمات پیمانکاری فرعی ارائه‌شده»';
																									|it = 'Formalizza l''arrivo delle materie prime dal committente';
																									|pl = 'Sporządź napływ surowców od właściciela surowców';
																									|tr = '""Ambar giriş fişi - Fason müşterisinden alınan"" düzenle'"));
	ComplianceWithRecommendations.Insert("IssueSpendingOrdersForGoods", NStr("vi = 'Hãy lập phiếu xuất kho';
																			|ru = 'Оформите расходные ордера на товары';
																			|en = 'Create goods issues'; fa = 'ایجاد حواله‌های انبار';
																			|it = 'Formalizza i mandati di pagamento per le merci';
																			|pl = 'Sporządź zlecenia wydania towarów';
																			|tr = 'Ambar çıkış fişlerini düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterSalesOfGoodsAndServices", NStr("vi = 'Hãy lập chứng từ giao hàng và cung cấp dịch vụ';
																				|ru = 'Оформите реализации товаров и услуг';
																				|en = 'Register customer invoice'; fa = 'Register customer invoice';
																				|it = 'Completare vendita di merci e servizi';
																				|pl = 'Sporządź sprzedaże towarów i usług';
																				|tr = 'Müşteri faturası düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterGoodsShipmentFromStorage", NStr("vi = 'Hãy lập chứng từ xuất hàng từ kho';
																					|ru = 'Оформите отгрузки товаров с хранения';
																					|en = 'Register VMI pick-up request from vendor'; fa = 'ثبت درخواست برداشت VMI از فروشنده';
																					|it = 'Formalizza le spedizione delle merci depositate';
																					|pl = 'Sporządź wysyłki towarów z przechowywania';
																					|tr = 'Ürünlerin ambardan sevkiyatını düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterGoodsReceivingForStorage", NStr("vi = 'Hãy lập chứng từ nhập hàng vào kho';
																					|ru = 'Оформите приемки товаров на хранение';
																					|en = 'Register goods receipt for storage'; fa = 'ثبت دریافت کالا برای انبار امانی';
																					|it = 'Formalizza l''accettazione delle merci in deposito';
																					|pl = 'Sporządź przyjęcie towarów na przechowywanie';
																					|tr = 'Depoya mal girişi düzenle'"));
	ComplianceWithRecommendations.Insert("RegisterInventoryConsumption", NStr("vi = 'Sử dụng tiêu dùng nội bộ';
																				|ru = 'Оформите внутреннее потребление';
																				|en = 'Register inventory consumption'; fa = 'Register inventory consumption';
																				|it = 'Оформите внутреннее потребление';
																				|pl = 'Register inventory consumption';
																				|tr = 'Dahili tüketimi oluşturun'"));
	Return ComplianceWithRecommendations;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfInventoryTransferDocumentRegistration);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tính chính xác của các giao dịch với hàng tồn kho.';
									|ru = 'Контроль корректности операций с товарно-материальными ценностями.';
									|en = 'Control the accuracy of transactions with inventory'; fa = 'Control the accuracy of transactions with inventory';
									|it = 'Контроль корректности операций с товарно-материальными ценностями.';
									|pl = 'Kontrola poprawności operacji z zapasami.';
									|tr = 'Stoklarla yapılan işlemlerin doğruluğunun kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ControlOfInventoryTransferDocumentRegistration");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc phản ánh các giao dịch chi tiết đến mặt hàng.';
									|ru = 'Контроль отражения операций с детализацией до номенклатуры.';
									|en = 'Control transaction recording in detail down to products.'; fa = 'Control transaction recording in detail down to products.';
									|it = 'Контроль отражения операций с детализацией до номенклатуры.';
									|pl = 'Kontrola odzwierciedlenia operacji z detalizacją do produktów.';
									|tr = 'Ayrıntılı ürün yansıması dahil işlem kaydı kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ConsolidatedControlOfRegistrationOfDocumentsOfCommodityRegisteredRecords");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc phản ánh các giao dịch tổng hợp theo mặt hàng có chi tiết đến chứng từ.';
									|ru = 'Контроль отражения операций сводно по номенклатуре с детализацией до документа.';
									|en = 'Control of summary transaction recording by items in detail down to document.'; fa = 'Control of summary transaction recording by items in detail down to document.';
									|it = 'Контроль отражения операций сводно по номенклатуре с детализацией до документа.';
									|pl = 'Kontrola odzwierciedlenia operacji skonsolidowana według produktów z detalizacją do dokumentu.';
									|tr = 'Belgeye kadar detaylandırma ile öğeye göre işlemlerin özet olarak yansımasının kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "WizardOfCorrectingCompanyStockBalanceMode");
	OptionDetails.LongDesc = NStr("vi = 'Chế độ trợ lý chỉnh sửa số dư hàng hóa trong các doanh nghiệp.';
									|ru = 'Режим помощника исправления остатков товаров организаций.';
									|en = 'Company stock balance correction wizard mode.'; fa = 'Company stock balance correction wizard mode.';
									|it = 'Режим помощника исправления остатков товаров организаций.';
									|pl = 'Tryb asystenty korekty stanu magazynowego firm.';
									|tr = 'İş yerlerinin ürün bakiyesini düzeltmek için sihirbaz modu.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DetailedRecords");
	OptionDetails.LongDesc = NStr("vi = 'Bản ghi chi tiết.';
									|ru = 'Детальные записи.';
									|en = 'Detailed records.'; fa = 'Detailed records.';
									|it = 'Детальные записи.';
									|pl = 'Szczegółowe zapisy.';
									|tr = 'Ayrıntılı kayıtlar.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf