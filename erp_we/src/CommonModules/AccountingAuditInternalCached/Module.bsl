///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Generates the structure of check tables and check groups for further use.
//
// Returns:
//    Structure:
//       * ChecksGroups - See AccountingAuditInternalCached.ChecksGroupsNewTable
//       * Checks       - See AccountingAuditInternalCached.NewChecksTable
//
Function AccountingChecks() Export
	
	ChecksGroups = ChecksGroupsNewTable();
	Checks       = NewChecksTable();
	
	AddAccountingSystemChecks(ChecksGroups, Checks);
	
	SSLSubsystemsIntegration.OnDefineChecks(ChecksGroups, Checks);
	AccountingAuditOverridable.OnDefineChecks(ChecksGroups, Checks);
	
	// For backward compatibility purposes.
	AccountingAuditOverridable.OnDefineAppliedChecks(ChecksGroups, Checks);
	ProvideReverseCompatibility(Checks);
	
	Return New FixedStructure("ChecksGroups, Checks", ChecksGroups, Checks);
	
EndFunction

// Returns an array of types that includes all possible configuration object types.
//
// Returns:
//    Array - an array of object types.
//
Function TypeDetailsAllObjects() Export
	
	TypesArray = New Array;
	
	MetadataKindsArray = New Array;
	MetadataKindsArray.Add(Metadata.Documents);
	MetadataKindsArray.Add(Metadata.Catalogs);
	MetadataKindsArray.Add(Metadata.ExchangePlans);
	MetadataKindsArray.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKindsArray.Add(Metadata.ChartsOfAccounts);
	MetadataKindsArray.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKindsArray.Add(Metadata.Tasks);
	
	For Each MetadataKind In MetadataKindsArray Do
		For Each MetadataObject In MetadataKind Do
			
			SeparatedName = StrSplit(MetadataObject.FullName(), ".");
			If SeparatedName.Count() < 2 Then
				Continue;
			EndIf;
			
			TypesArray.Add(Type(SeparatedName.Get(0) + "Object." + SeparatedName.Get(1)));
			
		EndDo;
	EndDo;
	
	Return New FixedArray(TypesArray);
	
EndFunction

Function ObjectsToExcludeFromCheck() Export
	
	Objects = New Array;
	SSLSubsystemsIntegration.OnDefineObjectsToExcludeFromCheck(Objects);
	
	Names = New Array;
	For Each Object In Objects Do
		Names.Add(Object.FullName());
	EndDo;
	
	Return New FixedArray(Names);
	
EndFunction

#EndRegion

#Region Private

// See AccountingAuditOverridable.OnDefineChecks
Procedure AddAccountingSystemChecks(ChecksGroups, Checks)
	
	ChecksGroup = ChecksGroups.Add();
	ChecksGroup.Description                 = NStr("vi = 'Kiểm tra hệ thống';
													|ru = 'Системные проверки';
													|en = 'System checks'; fa = 'System checks';
													|it = 'Verifiche di sistema';
													|pl = 'Systemowe sprawdzenia';
													|tr = 'Sistem kontrolleri'");
	ChecksGroup.Id                = "SystemChecks";
	ChecksGroup.AccountingChecksContext = "SystemChecks";
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("vi = 'Kiểm tra mục tin bắt buộc chưa điền';
													|ru = 'Проверка незаполненных обязательных реквизитов';
													|en = 'Check for empty required attributes'; fa = 'Check for empty required attributes';
													|it = 'Verifica degli attributi obbligatori non compilati';
													|pl = 'Sprawdzenie niewypełnionych wymaganych atrybutów';
													|tr = 'Doldurulmamış gerekli öznitelik kontrolü'");
	Validation.Reasons                      = NStr("vi = 'Đồng bộ sai dữ liệu với các ứng dụng khác hoặc kết nhập dữ liệu.';
													|ru = 'Некорректная синхронизация данных с другими приложениями или импорт данных.';
													|en = 'Invalid data synchronization with external applications or data import.'; fa = 'Invalid data synchronization with external applications or data import.';
													|it = 'Invalid data synchronization with external applications or data import.';
													|pl = 'Invalid data synchronization with external applications or data import.';
													|tr = 'Diğer uygulamalarla yanlış veri senkronizasyonu veya veri içe aktarma.'");
	Validation.Recommendation                 = NStr("vi = 'Tùy chỉnh lại đồng bộ dữ liệu hoặc điền thủ công mục tin bắt buộc.
		|Để thực hiện điều này, còn có thể sử dụng thay đổi mục tin theo nhóm (trong phân hệ Quản trị).
		|Trong trường hợp, phát hiện thấy các trường bắt buộc nhưng chưa điền trong các biểu ghi thì trong phần lớn
		|trường hợp, để tránh lỗi, cần điền các trường tương tứng trong chứng từ-nguồn ghi.';
		|ru = 'Перенастроить синхронизацию данных или заполнить обязательные реквизиты вручную.
		|Для этого можно также воспользоваться групповым изменением реквизитов (в разделе Администрирование).
		|В случае обнаружения незаполненных обязательных полей у регистров, то в большинстве
		|случаев, для устранения проблемы, достаточно заполнить соответствующие поля в документе-регистраторе.';
		|en = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.'; fa = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.';
		|it = 'Reimpostare la sincronizzazione dati o compilare manualmente gli attributi obbligatori.
		|Per questo è possibile anche utilizzare la modifica di gruppo degli attributi (nella sezione Administration).
		|In caso di rilevamento di campi e registri obbligatori non compilati, nella maggior parte
		|dei casi, per la risoluzione del problema, è sufficiente compilare i campi corrispondenti nel documento-registratore.';
		|pl = 'Ponownie ustaw synchronizację danych lub wypełnij wymagane atrybuty ręcznie.
		|W tym celu można również skorzystać z grupowej zmiany atrybutów (w sekcji Administrowanie).
		|W przypadku wykrycia niewypełnionych wymaganych pól w rejestrach, to w większości
		|przypadków, w celu rozwiązania problemu wystarczy wypełnić odpowiednie pola w dokumencie-rejestratorze.';
		|tr = 'Veri senkronizasyonunu yeniden yapılandır veya gerekli öznitelikleri manuel olarak doldur.
		|Ayrıca öznitelikleri toplu değiştirme özelliğini de kullanabilirsiniz (Yönetim bölümünde).
		|Kayıtlarda doldurulması gereken doldurulmamış alanlar tespit edilirse çoğu
		|durumda, problemi ortadan kaldırmak için kaydedici belgede ilgili alanları doldurmanız yeterlidir.'");
	Validation.Id                = "StandardSubsystems.CheckBlankMandatoryAttributes";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckUnfilledRequiredAttributes";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.SupportsRandomCheck = True;
	Validation.TurnedOff                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("vi = 'Kiểm tra tính toàn vẹn theo tham chiếu';
													|ru = 'Проверка ссылочной целостности';
													|en = 'Reference integrity check'; fa = 'Reference integrity check';
													|it = 'Verifica dell''integrità del collegamento';
													|pl = 'Sprawdzenie jednolitości odnośnika';
													|tr = 'Bağlantı bütünlüğü kontrolü'");
	Validation.Reasons                      = NStr("vi = 'Việc vô tình hoặc cố tình xóa dữ liệu mà không có kiểm soát tính toàn vẹn, lỗi phần cứng, đồng bộ hóa dữ liệu không chính xác với các chương trình khác hoặc kết nhập dữ liệu, lỗi trong công cụ của bên thứ ba (ví dụ, xử lý bên ngoài hoặc tiện ích mở rộng).';
													|ru = 'Случайное или преднамеренное удаление данных без контроля ссылочной целостности, сбои в работе оборудования, некорректная синхронизация данных с другими приложениями или импорт данных, ошибки в сторонних инструментах (например, внешних обработках или расширениях).';
													|en = 'Accidental or intentional data deletion without reference integrity control, equipment failures, invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'; fa = 'Accidental or intentional data deletion without reference integrity control, equipment failures, invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';
													|it = 'Accidental or intentional data deletion without reference integrity control, equipment failures, invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';
													|pl = 'Accidental or intentional data deletion without reference integrity control, equipment failures, invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';
													|tr = 'Bağlantı bütünlüğü kontrolü olmadan verilerin yanlışlıkla veya kasıtlı olarak silinmesi, donanım arızaları, diğer uygulamalarla yanlış veri senkronizasyonu veya veri içe aktarma, üçüncü taraf araçlarındaki hatalar (harici veri işlemcileri veya uzantılar gibi).'");
	Validation.Recommendation                 = NStr("vi = 'Phụ thuộc vào tình huống, cần chọn một trong số các phương án:
		|• phục hồi dữ liệu bị xóa từ bản sao dự phòng,
		|• hoặc xóa tham chiếu đến dữ liệu bị xóa (nếu không cần chúng nữa).';
		|ru = 'В зависимости от ситуации следует выбрать один из вариантов:
		|• восстановить удаленные данные из резервной копии,
		|• или очистить ссылки на удаленные данные (если они больше не требуются).';
		|en = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).'; fa = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).';
		|it = 'Dipendentemente dalla situazione, è necessario selezionare una delle varianti:
		|• ripristinare i dati eliminati dalla copia di backup,
		|• oppure eliminare il collegamento ai dati eliminati (se non sono più richiesti).';
		|pl = 'W zależności od sytuacji należy wybrać jeden z wariantów:
		|• przywrócić usunięte dane z kopii zapasowej,
		|• lub wyczyścić odnośniki na usunięte dane (jeśli nie są więcej potrzebne).';
		|tr = 'Duruma bağlı olarak bu seçeneklerden birini seçin:
		|• silinen verileri yedek kopyadan geri yükleyin,
		|• veya silinen verilerin bağlantılarını silin (artık gerekli değillerse).'");
	If Not Common.DataSeparationEnabled() Then
		Validation.Recommendation = Validation.Recommendation + Chars.LF + Chars.LF 
			+ NStr("vi = 'Để xóa liên kết đến dữ liệu bị xóa, cần:
			|• Kết thúc công việc của tất cả người sử dụng, đặt phong tỏa đăng nhập vào chương trình và thực hiện sao lưu dự phòng cơ sở thông tin;
			|• Khởi động Designer, menu Quản trị - Thử nghiệm và sửa chữa, sử dụng hai hộp kiểm để kiểm tra tính toàn vẹn lôgic và tham chiếu
			|  Xem chi tiết trên ITS: https://its.1c.eu/db/v83doc#bookmark:adm:TI000000142
			|• Chờ hoàn thành thử nghiệm và sửa chữa, bỏ chặn đăng nhập vào chương trình.
			|
			|Nếu làm việc trong cơ sở thông tin phân tán thì chỉ có thể khởi động sửa chữa tại nút chính.
			|Sau đó đồng bộ với các nút phụ.';
			|ru = 'Для очистки ссылок на удаленные данные следует:
			|• Завершить работу всех пользователей, установить блокировку входа в приложение и сделать резервную копию информационной базы;
			|• Запустить конфигуратор, меню Администрирование - Тестирования и исправление, включить два флажка для проверки логической и ссылочной целостности
			|  См. подробнее на ИТС: https://its.1c.eu/db/v83doc#bookmark:adm:TI000000142
			|• Дождаться завершения тестирования и исправления, снять блокировку входа в приложение.
			|
			|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.';
			|en = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			| For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; fa = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			| For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|it = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			| For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|pl = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			| For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|tr = 'Silinen verilerin bağlantılarını silmek için:
			|• Tüm kullanıcıların işlemlerini sonlandırın, uygulamaya giriş kilidini ayarlayın ve Infobase''i yedekleyin;
			|• Designer''ı başlatın, Yönetim - Test ve yama menüsünü açın, mantıksal bütünlük ve bağlantı bütünlüğü kontrolü için iki onay kutusunu işaretleyin
			| Daha fazla bilgi için ITD''ye bkz: https://its.1c.eu/db/v83doc#bookmark:adm:TI000000142
			|• Test ve yamanın tamamlanmasını bekleyin, programa giriş kilidini kaldırın.
			|
			|İşlem dağıtılmış Infobase''de yapılıyorsa yamayı sadece master düğümde başlatın.
			|Ardından alt düğümlerle senkronize edin.'");
	
	EndIf;
	Validation.Recommendation = Validation.Recommendation + Chars.LF
		+ NStr("vi = 'Trong trường hợp, tìm thấy các tham chiếu hỏng trong các biểu ghi thì trong phần lớn trường hợp, để tránh vấn đề
		|,cần loại bỏ các tham chiếu hỏng tương ứng trong các chứng từ-nguồn ghi.';
		|ru = 'В случае обнаружения битых ссылок в регистрах, то в большинстве случаев, для устранения проблемы
		|достаточно устранить соответствующие битые ссылки в документах-регистраторах.';
		|en = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.'; fa = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.';
		|it = 'In caso di rilevamento di collegamenti interrotti nei registri, nella maggior parte dei casi, al fine della risoluzione del problema,
		| è sufficiente eliminare i corrispondenti collegamenti interrotti nei documenti-registratori.';
		|pl = 'W przypadku wykrycia niedziałających odnośników w rejestrach, to w większości przypadków, aby usunąć problemy
		|wystarczy usunąć niedziałające odnośniki w dokumentach-rejestratorach.';
		|tr = 'Kayıtlarda bozulmuş bağlantıların tespit edildiği durumlarda, genellikle problemi ortadan kaldırmak için
		|ilgili bozuk bağlantıları kaydedici belgelerde kaldırmanız yeterlidir.'");
	Validation.Id                = "StandardSubsystems.CheckReferenceIntegrity1";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckReferenceIntegrity";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.SupportsRandomCheck = True;
	Validation.TurnedOff                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID            = ChecksGroup.Id;
	Validation.Description                   = NStr("vi = 'Kiểm tra tham chiếu vòng lặp';
													|ru = 'Проверка циклических ссылок';
													|en = 'Check for circular references'; fa = 'Check for circular references';
													|it = 'Verifica dei collegamenti ciclici';
													|pl = 'Sprawdzenie odnośników cyklicznych';
													|tr = 'Döngüsel bağlantı kontrolü'");
	Validation.Reasons                        = NStr("vi = 'Đồng bộ sai dữ liệu với các ứng dụng khác hoặc kết nhập dữ liệu.';
													|ru = 'Некорректная синхронизация данных с другими приложениями или импорт данных.';
													|en = 'Invalid data synchronization with external applications or data import.'; fa = 'Invalid data synchronization with external applications or data import.';
													|it = 'Invalid data synchronization with external applications or data import.';
													|pl = 'Invalid data synchronization with external applications or data import.';
													|tr = 'Diğer uygulamalarla yanlış veri senkronizasyonu veya veri içe aktarma.'");
	Validation.Recommendation                   = NStr("vi = 'Đối với một trong số các phần tử xóa tham chiếu đến phần tử lớp trên (để chỉnh sửa tự động, hãy nhấn tham chiếu dưới đây).
		|Nếu tiến hành công việc trong cơ sở thông tin phân tán (CSTTPT) thì cần khởi động chỉnh sửa chỉ trong nút chính.
		|Sau đó, thực hiện đồng bộ với nút phụ.';
		|ru = 'У одного из элементов очистить ссылку на родительский элемент (для автоматического исправления нажать ссылку ниже).
		|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
		|Затем выполнить синхронизацию с подчиненными узлами.';
		|en = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.'; fa = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.';
		|it = 'Presso uno degli elementi, eliminare il collegamento all''elemento padre (per la correzione automatica, cliccare sul collegamento in sotto).
		|Se il lavoro viene eseguito su una infobase distribuita, è necessario avviare la correzione solo nel nodo principale.
		|Poi eseguire la sincronizzazione con i nodi subordinati.';
		|pl = 'Dla jednego z elementów wyczyścić odnośnik do elementu nadrzędnego (w celu automatycznej korekty naciśnij poniższy odnośnik).
		|Jeśli praca jest prowadzona w rozproszonej bazie informacyjnej, to korektę należy uruchamiać tylko w węźle głównym.
		|Zatem wypełnij synchronizację z węzłami podrzędnymi.';
		|tr = 'Öğelerden birinde, ana öğenin bağlantısını temizleyin (otomatik düzeltme için aşağıdaki bağlantıya tıklayın).
		|İşlem dağıtılmış Infobase''de yapılıyorsa yamayı yalnızca ana düğümde başlatın.
		|Ardından alt düğümlerle senkronize edin.'");
	Validation.Id                  = "StandardSubsystems.CheckCircularRefs1";
	Validation.HandlerChecks             = "AccountingAuditInternal.CheckCircularRefs";
	Validation.GoToCorrectionHandler = "Report.AccountingCheckResults.Form.AutoCorrectIssues";
	Validation.AccountingChecksContext   = "SystemChecks";
	Validation.TurnedOff                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID            = ChecksGroup.Id;
	Validation.Description                   = NStr("vi = 'Kiểm tra phần tử định trước bị thiếu';
													|ru = 'Проверка отсутствующих предопределенных элементов';
													|en = 'Check for missing predefined items'; fa = 'Check for missing predefined items';
													|it = 'Verifica degli elementi predefiniti mancanti';
													|pl = 'Sprawdzenie brakujących predefiniowanych elementów';
													|tr = 'Eksik önceden tanımlanmış öğe kontrolü'");
	Validation.Reasons                        = NStr("vi = 'Đồng bộ sai dữ liệu với các ứng dụng khác hoặc kết nhập dữ liệu, lỗi trong các công cụ ngoài (ví dụ, bộ xử lý ngoài hoặc phần mở rộng).';
													|ru = 'Некорректная синхронизация данных с другими приложениями или импорт данных, ошибки в сторонних инструментах (например, внешних обработках или расширениях).';
													|en = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).'; fa = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';
													|it = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';
													|pl = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';
													|tr = 'Diğer uygulamalarla yanlış veri senkronizasyonu veya veri içe aktarma, üçüncü taraf araçlarındaki hatalar (harici veri işlemcisi veya eklentiler gibi).'");
	Validation.Recommendation                   = NStr("vi = 'Phụ thuộc vào tình huống, cần chọn một trong số các phương án sau:
		|• lựa chọn và chỉ ra một trong số các phần tử hiện có trong danh sách làm phần tử định trước; 
		|• phục hồi phần tử định trước từ bản sao dự phòng;
		|• tạo lại phần tử định trước bị thiếu (để thực hiện điều này, hãy nhấn tham chiếu dưới đây).';
		|ru = 'В зависимости от ситуации следует выбрать один из вариантов:
		|• подобрать и указать в качестве предопределенного один из существующих элементов в списке; 
		|• восстановить предопределенные элементы из резервной копии;
		|• создать отсутствующие предопределенные элементы заново (для этого нажмите ссылку ниже).';
		|en = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).'; fa = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).';
		|it = 'Dipendentemente dalla situazione, è necessario selezionare una delle varianti:
		|• Selezionare e indicare come predefinito uno degli elementi esistenti nell''elenco; 
		|• impostare gli elementi predefiniti dalla copia di backup;
		|• creare nuovamente gli elementi predefiniti mancanti (a tal fine, cliccare sul collegamento in basso).';
		|pl = 'W zależności od sytuacji należy wybrać jeden z wariantów:
		|• wybierz i określ jako predefiniowany jeden z istniejących elementów na liście; 
		|• przywróć predefiniowane elementy z kopii zapasowej;
		|• utwórz brakujące predefiniowane elementy od początku (aby to zrobić naciśnij poniższy odnośnik).';
		|tr = 'Duruma bağlı olarak aşağıdaki seçeneklerden birini seçin:
		|• listedeki mevcut öğelerden birini önceden tanımlanmış olarak seçin ve belirtin;
		|• yedek kopyadan önceden tanımlanmış öğeleri geri yükleyin;
		|• eksik önceden tanımlanmış öğeleri sıfırdan oluşturun (bunun için aşağıdaki bağlantıya tıklayın).'"); 
	If Not Common.DataSeparationEnabled() Then
		Validation.Recommendation = Validation.Recommendation + Chars.LF
			+ NStr("vi = 'Nếu công việc thực hiện trong cơ sở thông tin phân tán (CSTTPT) thì cần khởi động chỉnh sửa chỉ trong nút chính.
			|Sau đó, thực hiện đồng bộ với nút phụ.';
			|ru = 'Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.';
			|en = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; fa = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|it = 'Se il lavoro viene eseguito su una infobase distribuita, è necessario avviare la correzione solo nel nodo principale.
			|Poi eseguire la sincronizzazione con i nodi subordinati.';
			|pl = 'Jeśli praca jest prowadzona w rozproszonej bazie informacyjnej, to korygowanie należy uruchomić tylko w głównym weźle.
			|Zatem wykonaj synchronizację z podrzędnymi węzłami.';
			|tr = 'İşlem dağıtılmış Infobase''de yapılıyorsa yamayı yalnızca ana düğümde başlatın.
			|Ardından alt düğümlerle senkronize edin.'");
	EndIf;
	Validation.Id                  = "StandardSubsystems.CheckNoPredefinedItems";
	Validation.HandlerChecks             = "AccountingAuditInternal.CheckMissingPredefinedItems";
	Validation.GoToCorrectionHandler = "Report.AccountingCheckResults.Form.AutoCorrectIssues";
	Validation.AccountingChecksContext   = "SystemChecks";
	Validation.TurnedOff                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("vi = 'Kiểm tra sự trùng lặp phần tử định trước';
													|ru = 'Проверка дублирования предопределенных элементов';
													|en = 'Check for duplicate predefined items'; fa = 'Check for duplicate predefined items';
													|it = 'Verifica di duplicati degli elementi predefiniti';
													|pl = 'Sprawdzenie duplikowanych predefiniowanych elementów';
													|tr = 'Önceden tanımlanmış öğe tekrarı kontrolü'");
	Validation.Reasons                      = NStr("vi = 'Đồng bộ sai dữ liệu với các ứng dụng khác hoặc kết nhập dữ liệu.';
													|ru = 'Некорректная синхронизация данных с другими приложениями или импорт данных.';
													|en = 'Invalid data synchronization with external applications or data import.'; fa = 'Invalid data synchronization with external applications or data import.';
													|it = 'Invalid data synchronization with external applications or data import.';
													|pl = 'Invalid data synchronization with external applications or data import.';
													|tr = 'Diğer uygulamalarla yanlış veri senkronizasyonu veya veri içe aktarma.'");
	Validation.Recommendation                 = NStr("vi = 'Khởi động tìm kiếm và xóa bản trùng lặp (trong phân hệ Quản trị).';
													|ru = 'Запустить поиск и удаление дублей (в разделе Администрирование).';
													|en = 'Run duplicate cleaner in the Administration section.'; fa = 'Run duplicate cleaner in the Administration section.';
													|it = 'Avviare la ricerca ed eliminazione dei duplicati (nella sezione Administration).';
													|pl = 'Uruchom wyszukiwanie i usunięcie duplikatów (w sekcji Administrowanie).';
													|tr = 'Kopya Temizleyiciyi başlat (Yönetim bölümünde).'");
	If Not Common.DataSeparationEnabled() Then
		Validation.Recommendation = Validation.Recommendation + Chars.LF  
			+ NStr("vi = 'Nếu công việc thực hiện trong cơ sở thông tin phân tán (CSTTPT) thì cần khởi động chỉnh sửa chỉ trong nút chính.
			|Sau đó, thực hiện đồng bộ với nút phụ.';
			|ru = 'Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.';
			|en = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; fa = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|it = 'Se il lavoro viene eseguito su una infobase distribuita, è necessario avviare la correzione solo nel nodo principale.
			|Poi eseguire la sincronizzazione con i nodi subordinati.';
			|pl = 'Jeśli praca jest prowadzona w rozproszonej bazie informacyjnej, to korygowanie należy uruchomić tylko w głównym weźle.
			|Zatem wykonaj synchronizację z podrzędnymi węzłami.';
			|tr = 'İşlem dağıtılmış Infobase''de yapılıyorsa yamayı yalnızca ana düğümde başlatın.
			|Ardından alt düğümlerle senkronize edin.'");
	EndIf;
	Validation.Id                = "StandardSubsystems.CheckDuplicatePredefinedItems1";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckDuplicatePredefinedItems";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.TurnedOff                    = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("vi = 'Kiểm tra việc không có nút định trước của sơ đồ trao đổi';
													|ru = 'Проверка отсутствия предопределенных узлов плана обмена';
													|en = 'Check for missing predefined nodes in exchange plan'; fa = 'Check for missing predefined nodes in exchange plan';
													|it = 'Verifica di assenza di nodi predefiniti del piano di scambio';
													|pl = 'Sprawdzenie braku predefiniowanych węzłów planu wymiany';
													|tr = 'Değişim planının önceden tanımlanmış düğümlerinin eksiklik kontrolü'");
	Validation.Reasons                      = NStr("vi = 'Hành vi sai của ứng dụng khi làm việc ở các phiên bản nền tảng 1C:Enterprise cũ hơn.';
													|ru = 'Некорректное поведение приложения при работе на устаревших версиях платформы 1С:Предприятие.';
													|en = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version.'; fa = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version.';
													|it = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version.';
													|pl = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version.';
													|tr = '1C:Enterprise platformunun eski sürümlerinde çalışırken yanlış uygulama gidişatı.'");
	If Common.DataSeparationEnabled() Then
		Validation.Recommendation             = NStr("vi = 'Liên hệ dịch vụ hỗ trợ kỹ thuật.';
													|ru = 'Обратиться в техническую поддержку сервиса.';
													|en = 'Contact technical service support.'; fa = 'Contact technical service support.';
													|it = 'Rivolgersi al supporto tecnico del servizio.';
													|pl = 'Zwróć się do pomocy technicznej serwisu.';
													|tr = 'Servisin teknik desteğine başvurun.'");
	Else	
		Validation.Recommendation             = NStr("vi = '• Chuyển đến phiên bản nền tảng 1C:Interprise phiên bản 8.3.9.2033 trở lên;
			|• Kết thúc công việc của tất cả người sử dụng, chặn đăng nhập vào chương trình và tạo bản sao dự phòng cơ sở thông tin;
			|• Khởi động bộ thiết kế, menu Quản trị - Thử nghiệm và sửa chữa, sử dụng hai hộp kiểm để kiểm tra tính toàn vẹn lôgic và tham chiếu
			|  Xem chi tiết trên ITS: https://its.1c.eu/db/v83doc#bookmark:adm:TI000000142
			|• Chờ kết thúc thử nghiệm và sửa chữa, bỏ chặn đăng nhập vào chương trình.
			|
			|Nếu làm việc trong cơ sở thông tin phân tán thì chỉ có thể khởi động sửa chữa tại nút chính.
			|Sau đó đồng bộ với các nút phụ.';
			|ru = '• Перейти на версию платформы 1С:Предприятие 8.3.9.2033 или выше;
			|• Завершить работу всех пользователей, установить блокировку входа в приложение и сделать резервную копию информационной базы;
			|• Запустить конфигуратор, меню Администрирование - Тестирования и исправление, включить два флажка для проверки логической и ссылочной целостности
			|  См. подробнее на ИТС: https://its.1c.eu/db/v83doc#bookmark:adm:TI000000142
			|• Дождаться завершения тестирования и исправления, снять блокировку входа в приложение.
			|
			|Если работа ведется в распределенной информационной базе (РИБ), то исправление следует запускать только в главном узле.
			|Затем выполнить синхронизацию с подчиненными узлами.';
			|en = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			|  For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.'; fa = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			|  For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|it = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			|  For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|pl = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			|  For more information, see 1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';
			|tr = '• 1C:Enterprise 8.3.9.2033 veya üzeri bir platform sürümüne gidin;
			|• Tüm kullanıcıların işlerini tamamlayın, uygulama giriş kilidi ayarlayın ve Infobase''in yediğini alın;
			|• Designer''ı başlatın, Yönetim - Test ve Yamalama menüsüne gidin, mantıksal ve bağlantı bütünlüğü için iki onay kutusunu etkinleştirin
			| Daha fazlası için ITD''ye bakın: https://its.1c.eu/db/v83doc#bookmark:adm:TI000000142
			|• Testin ve yamalamanın tamamlanması bekleyin, program girişindeki kilidi kaldırın.
			|
			|Eğer iş dağıtılmış bilgi tabanında (DBT) gerçekleştirilirse, bu durumda sadece master düğümde yamalamanın başlatılması yapın.
			|Sonrasında ise senkronizasyonu alt düğümlerle gerçekleştirin.'");
	EndIf;
	Validation.Id                = "StandardSubsystems.CheckNoPredefinedExchangePlansNodes";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckPredefinedExchangePlanNodeAvailability";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.TurnedOff                    = True;
	
EndProcedure

// Creates a table of check groups
//
// Returns:
//   ValueTable:
//      * Description                 - String - a check group description.
//      * GroupID          - String - a string ID of the check group, for example: 
//                                       "SystemChecks", "MonthEndClosing", "VATChecks", and so on.
//                                       Required.
//      * Id                - String - The id of a check group. A mandatory parameter.
//                                       The id format is:
//                                       <Software name>.<Check id>.
//                                       For example, "StandardSubsystems.SystemChecks".
//      * AccountingChecksContext - DefinedType.AccountingChecksContext - a value that additionally
//                                       specifies the belonging of a data integrity check group to a certain category.
//      * Comment                  - String - a comment to a check group.
//
Function ChecksGroupsNewTable() Export
	
	ChecksGroups        = New ValueTable;
	ChecksGroupColumns = ChecksGroups.Columns;
	ChecksGroupColumns.Add("Description",                 New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("Id",                New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("GroupID",          New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("AccountingChecksContext", Metadata.DefinedTypes.AccountingChecksContext.Type);
	ChecksGroupColumns.Add("Comment",                  New TypeDescription("String", , , , New StringQualifiers(256)));
	
	Return ChecksGroups;
	
EndFunction

// Creates a check table.
//
// Returns:
//   ValueTable:
//      * GroupID                    - String - a string ID of the check group, for example: 
//                                                 "SystemChecks", "MonthEndClosing", "VATChecks", and so on.
//                                                 Required.
//      * Description                           - String - a check description displayed to a user.
//      * Reasons                                - String - a description of possible reasons that result in issue
//                                                 appearing.
//      * Recommendation                           - String - a recommendation on solving an appeared issue.
//      * Id                          - String - The id of an item. A mandatory parameter.
//                                                 The id format is:
//                                                 <Software name>.<Check id>.
//                                                 For example, "StandardSubsystems.SystemChecks".
//      * CheckStartDate                     - Date - a threshold date that indicates the boundary of the checked
//                                                 objects (only for objects with a date). Do not check objects whose date is less
//                                                 than the specified one. It is not filled in by default (
//                                                 check all).
//      * IssuesLimit                           - Number - a number of the checked objects. The default value is 1000. 
//                                                 If 0 is specified, check all objects.
//      * HandlerChecks                     - String - a name of the export handler procedure of the server common 
//                                                 module as ModuleName.ProcedureName. 
//      * GoToCorrectionHandler         - String - a name of the export handler procedure for client common 
//                                                 module to start correcting an issue in the form of "ModuleName.ProcedureName.
//      * NoCheckHandler                 - Boolean - a flag of the service check that does not have the handler procedure.
//      * ImportanceChangeDenied             - Boolean - if True, the administrator cannot change 
//                                                 the importance of this check.
//      * AccountingChecksContext           - DefinedType.AccountingChecksContext - a value that additionally 
//                                                 specifies the belonging of a data integrity check to a certain group 
//                                                 or category.
//      * AccountingCheckContextClarification - DefinedType.AccountingCheckContextClarification - a value 
//                                                 that additionally specifies the belonging of a data integrity check 
//                                                 to a certain group or category.
//      * AdditionalParameters                - ValueStorage - an additional check information for program
//                                                 use.
//      * Comment                            - String - a comment to the check.
//      * TurnedOff                              - Boolean - if True, the check will not be performed in the background on schedule.
//
Function NewChecksTable() Export
	
	Checks        = New ValueTable;
	ChecksColumns = Checks.Columns;
	ChecksColumns.Add("GroupID",                    New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Description",                           New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Reasons",                                New TypeDescription("String"));
	ChecksColumns.Add("Recommendation",                           New TypeDescription("String"));
	ChecksColumns.Add("Id",                          New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("CheckStartDate",                     New TypeDescription("Date", , , , , New DateQualifiers(DateFractions.DateTime)));
	ChecksColumns.Add("IssuesLimit",                           New TypeDescription("Number", , , New NumberQualifiers(8, 0, AllowedSign.Nonnegative)));
	ChecksColumns.Add("HandlerChecks",                     New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("GoToCorrectionHandler",         New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("NoCheckHandler",                 New TypeDescription("Boolean"));
	ChecksColumns.Add("ImportanceChangeDenied",             New TypeDescription("Boolean"));
	ChecksColumns.Add("AccountingChecksContext",           Metadata.DefinedTypes.AccountingChecksContext.Type);
	ChecksColumns.Add("AccountingCheckContextClarification", Metadata.DefinedTypes.AccountingCheckContextClarification.Type);
	ChecksColumns.Add("AdditionalParameters",                New TypeDescription("ValueStorage"));
	ChecksColumns.Add("ParentID",                  New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Comment",                            New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("TurnedOff",                              New TypeDescription("Boolean"));
	ChecksColumns.Add("SupportsRandomCheck",         New TypeDescription("Boolean"));
	Checks.Indexes.Add("Id");
	
	Return Checks;
	
EndFunction

Procedure ProvideReverseCompatibility(Checks)
	
	For Each Validation In Checks Do
		
		If ValueIsFilled(Validation.GroupID) Then
			Continue;
		EndIf;
		
		Validation.GroupID = Validation.ParentID;
		
	EndDo;
	
EndProcedure

#EndRegion