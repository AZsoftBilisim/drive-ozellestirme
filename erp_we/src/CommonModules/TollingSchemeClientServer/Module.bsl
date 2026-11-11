////////////////////////////////////////////////////////////////////////////
// The module "Tolling Systemaclientserver" contains procedures and functions for 
// working with the mechanism of production from tolling raw materials.
//
////////////////////////////////////////////////////////////////////////////
//

#Region Public


#Region BusinessTransactions

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return PredefinedValue("Enum.BusinessTransactions.TollManufacturing2_5");
	
EndFunction

#EndRegion

#Region RepresentationOfObjects

// Returns the synonym of the document Acceptance of goods storage in the toll-free scheme
//
// Returns:
//  String - 
//
Function SynonymForDocumentAcceptanceOfGoodsForStorage() Export
	
	Return NStr("vi = 'Tiếp nhận từ người đặt gia công';
				|ru = 'Поступление от давальца';
				|en = 'Receipt from material provider'; fa = 'دریافت از تأمین‌کننده مواد';
				|it = 'Ricezione dall''addetto alla lavorazione';
				|pl = 'Wpływ od właściciela surowców';
				|tr = 'Mal girişi — Verilen fason hizmetleri'");
	
EndFunction

// Returns "Transfer to giver" as a synonym for the document shippingreferences
// 
// Returns:
//  String - 
//
Function SynonymOfDocumentShipmentOfGoodsFromStorageTransferToGiver() Export
	
	Return NStr("vi = 'Chuyển giao cho người đặt gia công';
				|ru = 'Передача давальцу';
				|en = 'Goods issue — Subcontracting services delivered'; fa = 'حواله انبار — خدمات پیمانکاری فرعی ارائه‌شده';
				|it = 'Trasmissione al proprietario delle materie prime';
				|pl = 'Przekazanie właścicielowi surowców';
				|tr = 'Mal çıkışı — Fason hizmetleri teslim edildi'");
	
EndFunction

// Returns "Return to giver" as a synonym for the document shippingreferences
// 
// Returns:
//  String - 
//
Function SynonymOfDocumentShipmentOfGoodsFromStorageReturnToGiver() Export
	
	Return NStr("vi = 'Trả lại cho bên đặt gia công';
				|ru = 'Возврат давальцу';
				|en = 'Goods return — Subcontracting services delivered'; fa = 'برگشت کالا — خدمات پیمانکاری فرعی ارائه‌شده';
				|it = 'Restituzione del fornitore di materiali';
				|pl = 'Zwrot właścicielowi surowców';
				|tr = 'Sağlayıcıya iade'");
	
EndFunction

// Returns "The giver's goods repurchase" as a synonym for the document repurchase of accepted store goods
// 
// Returns:
//  String - 
//
Function SynonymForDocumentRedemptionOfGoodsAcceptedForStorage() Export
	
	Return NStr("vi = 'Người đặt gia công mua lại hàng hóa';
				|ru = 'Выкуп товаров давальца';
				|en = 'Redemption of provider goods'; fa = 'Redemption of provider goods';
				|it = 'Riscatto articoli del fornitore';
				|pl = 'Wykup towarów właściciela surowców';
				|tr = 'Malların sağlayıcıdan itfası'");
	
EndFunction

// Returns "The giver's goods repurchase" as a synonym for the document reporting and storage of goods
// 
// Returns:
//  String - 
//
Function SynonymOfDocumentReportOnWriteOffOfGoodsFromStorage() Export
	
	Return NStr("vi = 'Biên bản ghi giảm hàng hóa của bên đặt gia công';
				|ru = 'Отчет о списании товаров давальца';
				|en = 'Report on provider goods adjustment'; fa = 'Report on provider goods adjustment';
				|it = 'Report di storno merci del fornitore';
				|pl = 'Raport o rozchodowaniu towarów właściciela surowców';
				|tr = 'Sağlayıcı tarafından tedarik edilen malların gider yazılmasına ilişkin rapor'");
	
EndFunction

// Returns a synonym for the discrepancy report to be sent to the giver
//
// Returns:
//  String - 
//
Function SynonymOfDocumentCertificateOfDiscrepanciesTransferToGiver() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao cho bên đặt gia công';
				|ru = 'Акт о расхождениях после передачи давальцу';
				|en = 'Discrepancy report following Goods issue — Subcontracting services delivered'; fa = 'Discrepancy report following Goods issue — Subcontracting services delivered';
				|it = 'Акт о расхождениях после передачи давальцу';
				|pl = 'Discrepancy report following Goods issue — Subcontracting services delivered';
				|tr = 'Sağlayıcıya teslim edildikten sonra tutarsızlık raporu'");
	
EndFunction

// Returns a synonym for the discrepancy report for the refund to the giver
//
// Returns:
//  String - 
//
Function SynonymOfDocumentCertificateOfDiscrepanciesReturnOfRawMaterialsToGiver() Export
	
	Return NStr("vi = 'Biên bản chênh lệch sau khi trả lại nguyên vật liệu cho bên đặt gia công';
				|ru = 'Акт о расхождениях после возврата давальцу';
				|en = 'Discrepancy report following Goods return — Subcontracting services delivered'; fa = 'Discrepancy report following Goods return — Subcontracting services delivered';
				|it = 'Discrepancy report following Goods return — Subcontracting services delivered';
				|pl = 'Discrepancy report following Goods return — Subcontracting services delivered';
				|tr = 'Sağlayıcıya iadeden sonra tutarsızlık raporu'");
	
EndFunction

#EndRegion

#Region DestinationKeys
	

// The assignment key is the documents of acceptance for processing.
// 
// Returns:
//  String - Assignment Key Documents Of Acceptance For Processing
//
Function AssignmentKeyDocumentsOfAcceptanceForProcessing() Export
	
	Return "DocumentsOfAcceptanceForProcessing";
	
EndFunction
	
#EndRegion

#EndRegion