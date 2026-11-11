#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Gets a specialized task form
//
// Parameters:
//  TaskRef         - TaskRef - the task for which the form is obtained
//  RoutePointRef  - BusinessProcessRoutePointRef - the route point for which the form is obtained.
//
// Returns:
//   ClientApplicationForm   - a specialized form of task execution.
//
Function TaskExecutionForm(TaskRef, RoutePointRef) Export

	If RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.PrimaryContact
	   Or RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.Presentation
	   Or RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.Auction Then
		FormName = "BusinessProcess.StandardSale.Form.Interactions";
	ElsIf RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.ProposalPreparation Then
		 FormName = "BusinessProcess.StandardSale.Form.CommercialProposal";
	ElsIf RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.CustomerQualifications Then
			FormName = "BusinessProcess.StandardSale.Form.Client";
	ElsIf RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.CreatingOrder Then
		FormName = "BusinessProcess.StandardSale.Form.SalesOrder";
	ElsIf RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.Auction
		  Or RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.ConfirmationOfObligations
		  Or RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.MonitoringFulfillmentOfObligations
		  Or RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.FixingResultsOfWonTransaction
		  Or RoutePointRef = BusinessProcesses.StandardSale.RoutePoints.FixingResultsOfLostTrade Then
		FormName = "BusinessProcess.StandardSale.Form.Documents";
	EndIf;

	FormParameters = New Structure("Key", TaskRef);
	
	Return New Structure(
		"FormParameters, FormName", FormParameters, FormName);

EndFunction

// Called when executing a task from the list form.
//
// Parameters:
//   TaskRef                 - TaskRef.PerformerTask - the task that is being processed
//   BusinessProcessRef          - BusinessProcessRef.StandardSale - the task that is being processed 
//   BusinessProcessRoutePoint  - BusinessProcessRoutePointRef - route point
//
Procedure DefaultCompletionHandler(TaskRef, BusinessProcessRef, BusinessProcessRoutePoint) Export

EndProcedure

// Called when a task is redirected.
//
// Parameters:
//   TaskRef       - TaskRef.PerformerTask - the forwarded task.
//   NewTaskRef  - TaskRef.PerformerTask - task for a new performer.
//
Procedure OnForwardTask(TaskRef, NewTaskRef) Export
	
	BusinessProcessRef = Common.ObjectAttributeValue(TaskRef, "BusinessProcess");
	BusinessProcessObject = BusinessProcessRef.GetObject();
	LockDataForEdit(BusinessProcessObject.Ref);
	BusinessProcessObject.ExecutionResult = ExecutionResultOnForward(TaskRef) + BusinessProcessObject.ExecutionResult;
	SetPrivilegedMode(True);
	BusinessProcessObject.Write();
	
EndProcedure

// Get a description of the process task.
//
// Parameters:
//  BusinessProcessRoutePoint  - BusinessProcessRoutePointRef - the route point for which 
//                                 the description is returned.
//
// Returns:
//   String   - description for the route point.
//
Function PointDescription(BusinessProcessRoutePoint) Export

	If BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.PrimaryContact Then
		Return ?(GetFunctionalOption("UseEmailClient"), "- " + NStr("vi = 'lập kế hoạch và tiến hành liên hệ ban đầu (bắt buộc);';
																	|ru = 'запланируйте и проведите первичный контакт (обязательный);';
																	|en = 'schedule and establish initial contact (required);'; fa = 'schedule and establish initial contact (required);';
																	|it = 'programmare e eseguire un contatto primario (obbligatorio);';
																	|pl = 'zaplanuj i nawiąż wstępny kontakt (obowiązkowe);';
																	|tr = 'birincil iletişimi planla ve kaydet (zorunlu);'") + Chars.LF
			,"") +  "- " +  NStr("vi = 'làm rõ thể loại hàng hóa và mặt hàng mà khách hàng có thể quan tâm;
			|- hãy làm rõ dữ liệu về người liên hệ có khả năng quan tâm đến việc mua mặt hàng được đề xuất.';
			|ru = 'выясните товарные категории и номенклатуру, которые могут заинтересовать клиента;
			|- выясните данные о контактных лицах, потенциально заинтересованных в покупке предлагаемой номенклатуры.';
			|en = 'determine the product categories and products that may be of interest to the customer;
			|- find out the details of contact persons who are potentially interested in buying the offered products.'; fa = 'determine the product categories and products that may be of interest to the customer;
			|- find out the details of contact persons who are potentially interested in buying the offered products.';
			|it = 'scoprire le categorie merceologiche e la nomenclatura che possono essere di interesse per il cliente;
			|- trovare informazioni sulle persone di contatto potenzialmente interessate all''acquisto della nomenclatura proposta.';
			|pl = 'dowiedz się jakie kategorie towarów i towary mogą zainteresować klienta;
			|- uzyskaj dane osób do kontaktu, które mogą być potencjalnie zainteresowane zakupem proponowanych towarów.';
			|tr = 'müşterini ilgilendirebilen ürün kategorisi ve öğeyi açıkla;
			|- önerilen öğeyi satın almakla potansiyel olarak ilgilenen ilgili irtibat kişilerinin ayrıntılarını açıkla.'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.CustomerQualifications Then
		Return "- " +  NStr(
			"vi = 'hãy tập hợp và phân tích thông tin về khách hàng;
			|- hãy điền tập hợp thuộc tính bổ sung của khách hàng;
			|- hãy xác định khuôn khổ công việc theo vụ việc bằng cách chọn thỏa thuận (bắt buộc);
			|- làm rõ và ghi nhận quan hệ giữa khách hàng và các bạn hàng khác.';
			|ru = 'соберите и проанализируйте информацию о клиенте;
			|- заполните набор дополнительных свойств клиента;
			|- определите рамки работы по сделке - выберите соглашение (обязательный);
			|- выясните и зафиксируйте связи клиента с другими партнерами.';
			|en = 'Collect and analyze information about the customer;
			|- Fill in the set of additional customer properties;
			|- Specify the scope of work for the transaction - select an agreement (required);
			|- Find out and register the customer contacts with other partners.'; fa = 'Collect and analyze information about the customer;
			|- Fill in the set of additional customer properties;
			|- Specify the scope of work for the transaction - select an agreement (required);
			|- Find out and register the customer contacts with other partners.';
			|it = 'raccogliete e analizzate le informazioni sul cliente;
			|- compilate le caratteristiche aggiuntive del cliente;
			|- determinate l''ambito della transazione - selezionate un accordo (obbligatorio);
			|- scoprite e registrate i collegamenti del cliente con altri partner.';
			|pl = 'zgromadź i przeanalizuj informację o kliencie;
			|- wypełnij zestaw właściwości dodatkowych klienta;
			|- określ zakres pracy w sprawie umowy - wybierz umowę (obowiązkowy);
			|- wyjaśnij i zanotuj relacje klienta z innymi partnerami.';
			|tr = 'müşteri bilgilerini topla ve analiz et;
			|-ek müşteri özellikleri kümesini doldur;
			|-anlaşma üzerindeki işin kapsamını tanımla - bir anlaşma seç (zorunlu);
			|- müşterinin diğer iş ortakları ile olan bağlantılarını açıkla ve kaydet.'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.ProposalPreparation Then
		Return "- " + NStr(
			 "vi = 'hãy soạn và gửi báo giá (bắt buộc);
			|- tìm hiểu phản ứng của người mua;
			|- chỉ ra người liên hệ có thẩm quyền đưa ra quyết định mua hàng;
			|- thỏa thuận về thời hạn và địa điểm tiến hành minh họa, lập kế hoạch gặp gỡ.';
			|ru = 'подготовьте и отошлите коммерческое предложение (обязательный);
			|- узнайте реакцию покупателя;
			|- выясните контактное лицо, имеющее полномочия принять решение о закупке;
			|- договоритесь о сроках и месте проведения демонстрации, запланируйте встречу.';
			|en = 'Prepare and send a sales quotation (required);
			|- Find out about reaction of the customer;
			|- Find out who is the contact person entitled to make a decision on the purchase;
			|- Agree upon the time and place to hold the demonstration, schedule the meeting.'; fa = 'Prepare and send a sales quotation (required);
			|- Find out about reaction of the customer;
			|- Find out who is the contact person entitled to make a decision on the purchase;
			|- Agree upon the time and place to hold the demonstration, schedule the meeting.';
			|it = 'preparate e inviate l''offerta commerciale (obbligatorio);
			|- studiate la reazione dell''acquirente;
			|- informatevi sulla persona di contatto autorizzata a prendere la decisione sull''acquisto;
			|- accordatevi sui tempi e luogo di dimostrazione, programmate un incontro.';
			|pl = 'przygotuj i wyślij ofertę handlową (obowiązkowo);
			|- dowiedz się o reakcji nabywcy;
			|- dowiedz się o osobie do kontaktu, która jest uprawniona do podejmowania decyzji o zakupie;
			|- umów się o okresie i miejscu przeprowadzenia demonstracji i zaplanuj spotkanie.';
			|tr = 'satış teklifi hazırla ve gönder (zorunlu);
			|-müşteri tepkisini öğren;
			|-satın alma kararı verme yetkisine sahip irtibat kişisini öğren;
			|- gösterinin tarihi ve yeri üzerinde anlaş, toplantı planla.'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.Presentation Then
		Return "- " + NStr(
			"vi = 'hãy chuẩn bị tài liệu và thiết bị minh họa;
			|- chuẩn bị sự tham gia của các chuyên gia kỹ thuật;
			|- tiến hành minh họa;
			|- tìm hiểu phản ứng của khách hàng;
			|- tìm hiểu các mối quan hệ có thể có của khách hàng, những người liên lạc của khách hàng;
			|- tìm hiểu và ghi nhận đối thủ tiềm năng trong danh sách những người tham gia vào vụ việc.';
			|ru = 'подготовьте демонстрационные материалы и оборудование;
			|- подготовьте участие технических специалистов;
			|- проведите демонстрацию;
			|- выясните реакцию покупателя и решателя;
			|- выясните возможные взаимосвязи клиента, его контактных лиц;
			|- выясните и зарегистрируйте потенциальных конкурентов в списке участников сделки.';
			|en = 'Prepare illustrative material and equipment;
			|- Arrange for the technical specialists to participate;
			|- Hold a demonstration;
			|- Find out about reaction of the customer and the decision-maker;
			|- Find out about possible interrelations of the customer and their contact persons;
			|- Find out and register potential competitors in the transaction party list.'; fa = 'Prepare illustrative material and equipment;
			|- Arrange for the technical specialists to participate;
			|- Hold a demonstration;
			|- Find out about reaction of the customer and the decision-maker;
			|- Find out about possible interrelations of the customer and their contact persons;
			|- Find out and register potential competitors in the transaction party list.';
			|it = 'preparate materiale dimostrativo e attrezzature;
			|- preparate la partecipazione di specialisti tecnici;
			|- effettuate la dimostrazione;
			|- informatevi sulla reazione dell''acquirente e della persona autorizzata a prendere le decisioni;
			|- scoprite possibili relazioni del cliente e delle persone di contatto;
			|- scoprite e registrate eventuali concorrenti nell''elenco dei partecipanti alla transazione.';
			|pl = 'przygotuj materiały demonstracyjne i sprzęt;
			|- przygotuj współudział specjalistów technicznych;
			|- przeprowadź demonstrację;
			|- wyjaśnij reakcję nabywcy i osoby podejmującej decyzję;
			|- wyjaśnij możliwe związki wzajemne klienta, jego osób kontaktowych;
			|- wyjaśnij i zarejestruj potencjalnych konkurentów na liście uczestników umowy.';
			|tr = 'gösteri malzemeleri ve ekipmanı hazırla;
			|- teknik uzmanların katılımını hazırla;
			|- gösteriyi kaydet;
			|- müşterinin ve çözücünün tepkisini öğren;
			|- müşterinin, irtibat kişilerinin olası iş ilişkilerini öğren;
			|- potansiyel rakipleri bul ve satış fırsatı katılımcıları listesinde kaydet.'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.Auction Then
		Return "- " + NStr(
			"vi = 'phân tích môi trường vụ việc, bổ sung những người có ảnh hưởng và người ra quyết định vào danh sách những người tham gia;
			|- thực hiện các công việc cần thiết với những người có ảnh hưởng và người ra quyết định, đề xuất các khoản chiết khấu hợp lý;
			|- thống nhất đề xuất với khách hàng.';
			|ru = 'проанализируйте окружение сделки, дополните список ее участников влиятелями и решателем;
			|- проведите необходимую работу с влиятелями и решателем, предложите доступные скидки;
			|- согласуйте предложение с клиентом.';
			|en = 'Analyze the sales opportunity parties, add the influencer and the decision-maker to the list of its participants;
			|- Engage with the influencer and the decision-maker, offer available discounts;
			|- Agree upon the offer with the customer.'; fa = 'Analyze the sales opportunity parties, add the influencer and the decision-maker to the list of its participants;
			|- Engage with the influencer and the decision-maker, offer available discounts;
			|- Agree upon the offer with the customer.';
			|it = 'analizzate l''ambiente della transazione, completate l''elenco dei partecipanti con persone influenti e persone con il potere decisivo;
			|- occupatevi delle persone influenti e persone con il potere decisivo, offritegli sconti disponibili;
			|- coordinate l''offerta con il cliente.';
			|pl = 'przeanalizuj otoczenie umowy, uzupełnij listę jej uczestników osobami wpływającymi i osobą podejmującą decyzję;
			|- przeprowadź konieczną pracę z osobami wpływającymi i osobą podejmującą decyzję, zaproponuj dostępne rabaty;
			|- uzgodnij ofertę z klientem.';
			|tr = 'satış fırsatı ortamını analiz et, katılımcılarının listesini etkileyiciler ve bir çözücü ile tamamla;
			|- etkileyici ve çözücüler ile gerekli çalışmaları yap, uygun indirimler sun;
			|- teklifi müşteri ile onayla.'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.CreatingOrder Then
		Return "- " + NStr(
			"vi = 'chỉ ra pháp nhân của bạn hàng (bắt buộc);
			|- tạo đơn hàng của khách (bắt buộc).';
			|ru = 'уточните юридическое лицо партнера (обязательный);
			|- сформируйте заказ клиента (обязательный).';
			|en = 'Specify the partner legal entity (required);
			|- Generate the sales order (required).'; fa = 'Specify the partner legal entity (required);
			|- Generate the sales order (required).';
			|it = 'precisate il tipo di persona giuridica del partner (facoltativo);
			|- generate l''ordine del cliente (obbligatorio).';
			|pl = 'uściślij osobę prawną partnera (obowiązkowo);
			|- utwórz zamówienie klienta (obowiązkowo).';
			|tr = 'iş ortağının tüzel kişisini belirt (zorunlu);
			|- müşteri siparişini oluştur (zorunlu).'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.ConfirmationOfObligations Then
		Return "- " +  NStr("vi = 'khi cần thiết hãy lập hóa đơn thanh toán và chờ nhận khoản ứng trước hoặc
			| tiến hành giao hàng (bắt buộc).';
			|ru = 'при необходимости выставите счет на оплату и дождитесь поступления авансового платежа или
			| произведите отгрузку (обязательный).';
			|en = 'If necessary, issue a commercial invoice and wait for the advance payment or
			| carry out shipment (required).'; fa = 'If necessary, issue a commercial invoice and wait for the advance payment or
			| carry out shipment (required).';
			|it = 'se necessario emettete la fattura e attendete l''acconto o 
			|effettuate la spedizione (obbligatorio).';
			|pl = 'w razie konieczności wystaw fakturę do płatności i doczekaj się wpływu płatności zaliczkowej lub
			|wykonaj wysyłkę (obowiązkowo).';
			|tr = 'gerekirse, ödeme için ticari fatura düzenle ve avans ödemesinin gelmesini bekle veya
			| sevkiyat yap (zorunlu).'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.MonitoringFulfillmentOfObligations Then
		Return "- " + NStr(
			"vi = 'kiểm soát nhận thanh toán (bắt buộc);
			|- kiểm soát giao hàng và vận chuyển (bắt buộc).';
			|ru = 'проконтролируйте поступление платежей (обязательный);
			|- проконтролируйте отгрузки и доставки (обязательный).';
			|en = 'Make sure the payment is received (required);
			|- Make sure shipments and deliveries are performed (required).'; fa = 'Make sure the payment is received (required);
			|- Make sure shipments and deliveries are performed (required).';
			|it = 'verificate l''arrivo dei pagamenti (obbligatorio);
			|- controllate le spedizioni e le consegne (obbligatorio).';
			|pl = 'przekontroluj wpływ płatności (obowiązkowo);
			|- przekontroluj wysyłki i dostawy (obowiązkowo).';
			|tr = 'ödeme girişini kontrol et (zorunlu);
			|- sevkiyat ve teslimatları kontrol et (zorunlu).'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.FixingResultsOfWonTransaction Then
		Return "- " + NStr(
			"vi = 'kiểm soát bộ chứng từ gốc;
			|- kiểm soát đầy đủ và chính xác thông tin đã nhập theo vụ việc;
			|- kiểm soát việc hoàn tất thanh toán và giao hàng;
			|- kiểm soát bộ chứng từ gốc.';
			|ru = 'проконтролируйте комплектность первичных документов;
			|- проконтролируйте полноту и корректность внесенной по сделке информации;
			|- проконтролируйте завершение платежей и поставок;
			|- проконтролируйте комплектность первичных документов.';
			|en = 'Make sure the source documents are complete;
			|- Make sure the transaction information is complete and correct;
			|- Make sure the payments and supplies are completed;
			|- Make sure the source documents are complete.'; fa = 'Make sure the source documents are complete;
			|- Make sure the transaction information is complete and correct;
			|- Make sure the payments and supplies are completed;
			|- Make sure the source documents are complete.';
			|it = 'controllate che il pacchetto primario di documenti sia completo;
			|- controllate che le informazioni sulla transizione siano complete e corrette;
			|- controllate il completamento dei pagamenti e delle consegne;
			|- controllate che i documenti primari siano completi.';
			|pl = 'przekontroluj kompletność podstawowych dokumentów;
			|- przekontroluj całość i poprawność wprowadzonej informacji, dotyczącej umowy;
			|- przekontroluj zakończenie płatności i dostaw;
			|- przekontroluj kompletność podstawowych dokumentów.';
			|tr = 'birincil belgelerin bütünlüğünü kontrol et;
			|- satış fırsatında girilen bilgilerin eksiksizliğini ve doğruluğunu kontrol et;
			|- ödemelerin ve tedariklerin tamamlanmasını kontrol et;
			|- birincil belgelerin bütünlüğünü kontrol et.'");
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.FixingResultsOfLostTrade Then
		Return "- " + NStr(
			"vi = 'kiểm soát việc không thực hiện trách nhiệm theo vụ việc;
			|- chỉ ra nguyên nhân thua vụ việc (bắt buộc);
			|- kiểm soát đầy đủ và chính xác thông tin đã nhập vào vụ việc.';
			|ru = 'проконтролируйте отсутствие обязательств по сделке;
			|- укажите причину проигрыша сделки (обязательный);
			|- проконтролируйте полноту и корректность внесенной по сделке информации.';
			|en = 'Make sure there are no transaction obligations;
			|- Specify the reason for losing the transaction (required); 
			|- Make sure the transaction information is complete and correct.'; fa = 'Make sure there are no transaction obligations;
			|- Specify the reason for losing the transaction (required); 
			|- Make sure the transaction information is complete and correct.';
			|it = 'controllate che non vi siano obblighi derivanti dalla transazione;
			|- indicate la causa per cui la transazione non è andata a buon fine (obbligatorio);
			|- controllate che le informazioni sulla transazione siano corrette e complete.';
			|pl = 'przekontroluj brak obowiązków dotyczących umowy;
			|- podaj przyczynę przegranej umowy (obowiązkowo);
			|- przekontroluj całość i poprawność wprowadzonej informacji, dotyczącej umowy.';
			|tr = 'satış fırsatı kapsamındaki yükümlülüklerin bulunmadığını kontrol et;
			|- satış fırsatı kaybının nedenini belirt (zorunlu);
			|- satış fırsatında girilen bilgilerin eksiksizliğini ve doğruluğunu kontrol et.'");
	EndIf;

EndFunction

// Get a typical task completion date in days.
//
// Parameters:
//  BusinessProcessRoutePoint  - BusinessProcessRoutePointRef - the route point for which 
//                                 the typical due date is returned.
//
// Returns:
//   Number   - typical execution period for a route point.
//
Function TaskDueDate(BusinessProcessRoutePoint) Export

	If BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.PrimaryContact Then
		Return 2;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.CustomerQualifications Then
		Return 2;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.ProposalPreparation Then
		Return 3;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.Presentation Then
		Return 5;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.Auction Then
		Return 7;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.CreatingOrder Then
		Return 1;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.ConfirmationOfObligations Then
		Return 2;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.MonitoringFulfillmentOfObligations Then
		Return 14;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.FixingResultsOfWonTransaction Then
		Return 1;
	ElsIf BusinessProcessRoutePoint = BusinessProcesses.StandardSale.RoutePoints.FixingResultsOfLostTrade Then
		Return 1;
	EndIf;

EndFunction

// Returns a list of process stages when it is scheduled to run
//
// Returns:
//   Array   - contains a list of business process stages.
//
Function StageList() Export

	MStages = New Array;
	MStages.Add(Catalogs.ProcessesStates.PrimaryContact);
	MStages.Add(Catalogs.ProcessesStates.CustomerQualifications);
	MStages.Add(Catalogs.ProcessesStates.ProposalGeneration);
	MStages.Add(Catalogs.ProcessesStates.Presentation);
	MStages.Add(Catalogs.ProcessesStates.HarmonizationOfTerms);
	MStages.Add(Catalogs.ProcessesStates.PreparationForExecutionOfObligations);
	MStages.Add(Catalogs.ProcessesStates.LiabilityFulfillment);

	Return MStages;

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(SubjectOf.Partner)
	|	OR ValueAllowed(Author)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

Function ExecutionResultOnForward(Val TaskRef)
	
	StringFormat = NStr("vi = '%1, %2 đã chuyển hướng nhiệm vụ:
	                    |%3';
	                    |ru = '%1, %2 перенаправил(а) задачу:
	                    |%3';
	                    |en = '%1, %2 forwarded the task:
	                    |%3'; fa = '%1, %2 forwarded the task:
	                    |%3';
	                    |it = '%1%2 ha reindirizzato il task:
	                    |%3';
	                    |pl = '%1, %2 przekierował(a) zadanie:
	                    |%3';
	                    |tr = '%1, %2görevi yönlendirdi:
	                    |%3'");
	                    
	TaskDetails__ = Common.ObjectAttributesValues(TaskRef, "CompletionDate, Performer, ExecutionResult");
	
	Comment = TrimAll(TaskDetails__.ExecutionResult);
	Comment = ?(IsBlankString(Comment), "", Comment + Chars.LF);
	Result = StrTemplate(StringFormat,
	              TaskDetails__.CompletionDate,
	              TaskDetails__.Performer,
	              Comment);
	
	Result = Result + Chars.LF;
	
	Return Result;

EndFunction

#EndRegion

#EndIf
