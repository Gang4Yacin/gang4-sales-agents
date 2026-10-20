-- Correspondance marque (BusinessClient) -> company Attio pour la réconciliation produit (crm-sync §4b).
-- Calculée le 20/10/2026 par domaine puis par nom ; 3 corrections manuelles (doublons Attio) :
-- ATM Gaming - ES et Wecasa Wellness rattachées aux companies de leur marque mère, Bene Bono à sa fiche benebono.co.
-- Non rattachées (le run les traitera) : Hello Beauties, Mademoiselle Confettis.
-- À exécuter une fois, après relecture (Supabase bksiaeiqzmoaxvkdtspn).
insert into sales.processed_items (source, external_id, attio_object_type, attio_record_id, status, processed_at)
values
  ('business_client', '8444ef97-f233-46e2-a8e7-731c2ff69a77', 'companies', '8301e738-6da6-4385-b795-f197c12e07bd', 'processed', now()),  -- Abby
  ('business_client', 'aabd3526-2ff0-4cba-b760-feb2caa49a98', 'companies', 'e3b9506a-e76c-47f2-aa63-41efd26fe397', 'processed', now()),  -- AlloVoisins
  ('business_client', 'af13708f-acb9-4825-918e-3f7e2a99ae47', 'companies', 'd2461b62-6071-45bd-b128-c918dfa8c8b7', 'processed', now()),  -- Aloe Paris
  ('business_client', '43917b20-6728-4122-b8b5-bfe1793e581d', 'companies', '0e1d0094-b55c-41e7-a484-57e75bf24271', 'processed', now()),  -- Araw
  ('business_client', 'f3c0e92c-c651-4550-9796-595d79f954cb', 'companies', 'a647ec81-f131-4f1c-926f-edf5c6fd47cf', 'processed', now()),  -- ATM Gaming
  ('business_client', 'e33e4f5b-cf9c-4ff9-8560-bb10c66a506b', 'companies', 'a647ec81-f131-4f1c-926f-edf5c6fd47cf', 'processed', now()),  -- ATM Gaming - ES
  ('business_client', '5a847566-f56d-4ac7-bf05-7e124fad4c96', 'companies', '77b24fdd-0699-4e6b-b828-7de169c864a5', 'processed', now()),  -- Atma
  ('business_client', '14eedc97-0edb-4c49-8f6f-45bfeb994bb6', 'companies', '23d7fe89-7bfe-468e-b84e-8e14de4f3c08', 'processed', now()),  -- Avatacar
  ('business_client', '16f24999-2c1e-49e1-b3f0-ff92583e268b', 'companies', 'dca72c0c-245c-436e-a7cd-55e561a41540', 'processed', now()),  -- Baobab Labs
  ('business_client', '10c03dd0-7dc5-4064-8669-efb2aa3930ae', 'companies', 'd18b9087-3d9d-42d1-bdc5-e9ef0dd754dc', 'processed', now()),  -- Bene Bono
  ('business_client', '1788ae7d-fb41-430d-b915-a75dd918c53f', 'companies', '55efd0c2-6f3a-4958-98ba-d1dca435c037', 'processed', now()),  -- Besti
  ('business_client', '74f64073-9a85-43fb-97a3-085bc4380b29', 'companies', '8832aeb9-74a9-5c55-b164-780f6d8b0615', 'processed', now()),  -- Boku
  ('business_client', '5a8cb2d2-ec23-4bc5-ac0a-d4beb654ba59', 'companies', '22adeb87-c326-452c-a8b7-50273fb47523', 'processed', now()),  -- bpm
  ('business_client', 'e6dc5bfd-e3b6-49be-96b3-d328752352ce', 'companies', '7f864b2a-cba3-4411-8539-a80560063c67', 'processed', now()),  -- Bricks
  ('business_client', 'ebf9914d-7447-4642-ac52-32cddb650a80', 'companies', '08b7d7d8-5828-590f-baf3-cce6eaeafbfe', 'processed', now()),  -- Caats
  ('business_client', 'faa41cc5-68ee-4b59-97cb-a644469feb02', 'companies', 'eb2123e8-69f9-4b4c-b1bc-f849e945fb9e', 'processed', now()),  -- Charlotte Bio
  ('business_client', '774aada2-60c7-40a0-aeff-130193aef16b', 'companies', '4711a80a-2f55-4322-a9a6-b30ef24ce88a', 'processed', now()),  -- Cherico
  ('business_client', 'f0754a64-db53-49a0-a8d8-383b3c4d3196', 'companies', '0a59cb7d-3c8b-4b8f-b4c7-2018a9f3cb7a', 'processed', now()),  -- Circular
  ('business_client', 'ce4f4868-7c04-465d-bcc8-5287ff45c416', 'companies', '8aa47c07-bb4d-4545-8261-444ba2d2402a', 'processed', now()),  -- Cut by Fred
  ('business_client', '32eab999-7f29-4c6b-abd7-eee5f52d32f7', 'companies', 'f54cd196-4051-468f-a839-a1983d5f9053', 'processed', now()),  -- Cuure
  ('business_client', 'fda43ef0-e41d-43fa-adb9-7331d3b7585f', 'companies', '1d8eda5c-2a26-4ea9-8cb1-e664692903a4', 'processed', now()),  -- Cygnes
  ('business_client', '155cbb44-c744-4f4d-b3c8-5aad67748372', 'companies', '3fb00b7a-1f42-410f-abfc-dfd92b297db1', 'processed', now()),  -- Deejo
  ('business_client', '189ef453-e01e-4647-bd32-fece313344a7', 'companies', '8e60ae38-1f0e-5d8f-88c6-7ee5aba4954c', 'processed', now()),  -- En Cavale
  ('business_client', 'e3541a05-6f82-4d3e-b6a1-85576b8d69fd', 'companies', '1f731237-e813-5441-95e0-13d65b478617', 'processed', now()),  -- ENDRO Cosmétiques
  ('business_client', '8b94ee7d-9c55-4741-a7f4-bac50390340f', 'companies', '3cf55823-2a26-5bc6-9800-9e4cd991962f', 'processed', now()),  -- Epycure
  ('business_client', '4222e588-9cc3-4777-9fbf-8344b88264fb', 'companies', '3ce8044e-5111-4e2e-a3c9-6df97a6c3d2c', 'processed', now()),  -- Fempo
  ('business_client', 'f06a6368-7d28-4db6-af7e-1624a0d644ae', 'companies', 'c7ac78c9-1ca6-427f-bcce-874f510a6598', 'processed', now()),  -- Fleurus Presse
  ('business_client', '02081263-b00f-4bd2-96c0-ff2a98de1db7', 'companies', '39774975-747b-4e61-a5b0-f13923a32c17', 'processed', now()),  -- Gourmandiz
  ('business_client', 'a1c5830f-5889-4ce1-9872-7cffe859815c', 'companies', '5a2329a9-82f8-47e4-8eb2-54ca2bc4a660', 'processed', now()),  -- HomeExchange
  ('business_client', '6d48b50b-0a13-471e-a5d7-7eeb1f30c3c3', 'companies', '8273a15f-1685-496e-ab9c-3af4f842f245', 'processed', now()),  -- Horace
  ('business_client', '0cd405d1-2eac-4747-8d1d-6bb078e933dd', 'companies', 'f8d51cb5-1b1e-5626-86e2-0dec39378bda', 'processed', now()),  -- Inga
  ('business_client', 'e1a045dc-d5b1-45dd-9cd7-330a9cf332d1', 'companies', '0a0d62cc-b7ac-4a07-ad0b-2d5bc871c540', 'processed', now()),  -- Insentials
  ('business_client', 'b26a03b4-8562-43f3-b177-8e8e22e7cca9', 'companies', '960cbed5-a7c9-44f1-bd8b-369e911d3f0f', 'processed', now()),  -- Jho
  ('business_client', '3aede251-1280-4e9d-9e61-89f761d007cb', 'companies', '8ef6ea32-4c7a-4dbd-9e2c-1615cfd5ecd6', 'processed', now()),  -- JNPR
  ('business_client', '0a1a4781-69ae-454d-bdc4-553b3d532d8c', 'companies', '6fec21e8-cade-512b-b113-6059de6eea32', 'processed', now()),  -- Jolly Mama
  ('business_client', '46370f8e-ce79-4577-9010-eaefa8a27d2e', 'companies', 'b47e5bcf-4da4-4c84-938c-1d0edcd9ceb5', 'processed', now()),  -- Kimo Sofa
  ('business_client', '1dbf1dea-7175-4141-98bc-27c2d3ba20b2', 'companies', '13ba754f-0d21-45e1-828b-f1746bd155d6', 'processed', now()),  -- La Brigade de Véro
  ('business_client', 'e33adfaa-eecc-4593-965c-1e939aec6192', 'companies', '44cb3258-223f-49b7-a0aa-723efea34f6d', 'processed', now()),  -- La Marque En Moins
  ('business_client', 'e78ca219-a0c7-44eb-b47f-edbdbc099a5d', 'companies', '889b4cfa-5961-47c1-9dcc-086f167b9802', 'processed', now()),  -- La Première Brique
  ('business_client', 'f6bc9f3e-8ddb-47a9-83cf-8e705dfa2f57', 'companies', 'c31cc938-e6bf-4289-baf2-22468cba81ae', 'processed', now()),  -- Le Petit Lunetier
  ('business_client', '1ffafb07-a625-4f74-9131-ec97cf833ca2', 'companies', 'a6cb50bd-9d41-57fd-ad11-a485469c57d6', 'processed', now()),  -- Les Commis
  ('business_client', 'a83fcda6-b270-4030-81bd-7d3738ae320d', 'companies', 'a4b0f035-1112-5308-995c-9fb63feefeda', 'processed', now()),  -- Les Mini Mondes
  ('business_client', '65d92de2-c5a8-4cf7-836d-ce05248ee7ae', 'companies', '0b2dce34-ddba-4dab-94ac-c812fb2e898b', 'processed', now()),  -- Les Petits Prödiges
  ('business_client', 'ac4a1854-287c-451b-b3a5-4cc5a1458482', 'companies', 'd54f3f51-043a-4c52-bad9-c8e9a7791ecf', 'processed', now()),  -- Limova
  ('business_client', '39c19901-d84d-4e8b-b77a-cae00154ded4', 'companies', 'b2f3fa92-7de2-54f0-a45d-54dda2e5e6f1', 'processed', now()),  -- Little Cigogne
  ('business_client', 'c594501e-db60-4b08-b669-50c79079433c', 'companies', 'e757d298-c448-48a9-87eb-b395b3aaea10', 'processed', now()),  -- Lovys
  ('business_client', '1db7f9e9-5015-48e1-b21f-5e233b4404ee', 'companies', '4b66536f-f87a-44ee-9215-05147f99e78e', 'processed', now()),  -- Lunii
  ('business_client', '1f7a48f0-d853-4624-8095-237400db0583', 'companies', 'a01762e7-5692-4eeb-aedd-50bd9031f73d', 'processed', now()),  -- Maju
  ('business_client', 'e7506fb4-6595-4c12-95fe-3f074b20fbb2', 'companies', 'ea5a1b05-a8d7-4d8f-96ff-0e35ddde0f5e', 'processed', now()),  -- May
  ('business_client', 'c8c82d6a-001b-4010-97dd-61d7aa02e4c0', 'companies', '1ea64824-a166-4a5c-9fdf-217653be9159', 'processed', now()),  -- MB Heritage
  ('business_client', '6f31e335-7b9c-4ec3-bfb1-8c8164e32817', 'companies', '11eb4f26-a6de-49ac-ae11-ef67ae9f8bde', 'processed', now()),  -- Mium lab
  ('business_client', '9ac0bf2d-bf43-4b8f-bde2-95e88288841d', 'companies', 'ff990e1b-1209-4204-8952-6913809b995d', 'processed', now()),  -- Morphea
  ('business_client', '8dad7c57-1c8b-46cb-8447-68d14ae4e4fc', 'companies', '38526c39-b579-4ad3-be92-27503002d577', 'processed', now()),  -- My Little Coupon
  ('business_client', 'e6e55594-be59-4e0e-bd81-c2f93f667ca8', 'companies', '84d2b74a-a051-4c4f-b90d-a2b50fd452e2', 'processed', now()),  -- Oma & Me
  ('business_client', '523fff01-6993-4b98-bb30-74a138df7187', 'companies', '22ee3f93-bb3c-43cc-bcfd-7e9dc49728d1', 'processed', now()),  -- Perifit
  ('business_client', '10763b1c-a3cc-45ab-898a-e1efd71c423b', 'companies', 'b2f3fa92-7de2-54f0-a45d-54dda2e5e6f1', 'processed', now()),  -- Plumaïa
  ('business_client', '69919cca-a00a-4559-908f-e9f69f7f789a', 'companies', 'd3110d73-8536-5b10-a0e1-7f20c4f3112c', 'processed', now()),  -- Pomponne
  ('business_client', '943221cc-7178-4459-b105-2f74a203221d', 'companies', '6cae7168-1ab1-4c98-990c-ba5a12b286f8', 'processed', now()),  -- Poppins
  ('business_client', '36059410-6873-471d-8e7e-8df290525826', 'companies', 'f5c92b9a-e7f7-453a-bd21-c0d156cdf128', 'processed', now()),  -- Puissante
  ('business_client', 'caea436c-4983-4a5d-b59a-c95359987274', 'companies', '9607a3d5-448e-5df2-9b96-e36ab8f1072f', 'processed', now()),  -- QRU
  ('business_client', '37858e3f-7ac3-49f0-ab70-0ed552395efd', 'companies', '13e0ff16-31f2-44d6-b55c-06ba313ab8f1', 'processed', now()),  -- Reverso
  ('business_client', '1e4a127e-2eea-42d9-8caf-09d8e87a6596', 'companies', 'b7455254-57a9-442a-b5ac-f0cdd97668da', 'processed', now()),  -- ROSEGOLD Paris
  ('business_client', 'f7246e94-184e-4ca3-8aaa-5d1ce74e4293', 'companies', 'bd148b8c-ce45-49e1-81f8-56ea56a9aae2', 'processed', now()),  -- Réjeanne
  ('business_client', '2dde8d34-7ca8-4260-9f68-b8e64fe0a405', 'companies', '47b73611-cef8-4eaa-b962-61ca43ff9307', 'processed', now()),  -- Seoni
  ('business_client', 'b2ebd91b-6ac2-4a4e-a506-9854e59627fe', 'companies', '39d59002-232d-4759-b97b-cd97ab067bfe', 'processed', now()),  -- Sisters Republic
  ('business_client', '6ffcd729-b0b6-450f-9386-6c2f4ce6130e', 'companies', '91c1d7a8-d388-5d7c-88b3-c579449a0d12', 'processed', now()),  -- Skin & Out
  ('business_client', '199c249f-a248-4788-822a-56890069977e', 'companies', '6094829d-181b-504c-871b-38ad5a2813db', 'processed', now()),  -- SmartWorkout
  ('business_client', 'ea5462f5-6f17-4d9a-bc90-8409e36e021f', 'companies', '608ebf32-79b2-4ca8-91cf-d351cdc0bb5b', 'processed', now()),  -- SPRiNG
  ('business_client', 'fdbd6659-f36e-4029-9067-60d59637ea8e', 'companies', 'ca93458d-ad62-4dab-8605-586916a29ad7', 'processed', now()),  -- Sync
  ('business_client', 'f48543db-3e5e-41e9-8514-2ed137bf5ec9', 'companies', '3dec7406-70c5-4fd3-8419-49892d72f738', 'processed', now()),  -- Tediber
  ('business_client', 'a3347288-e430-4ca3-8caa-f87943557864', 'companies', 'b6920cf1-65d6-5822-a980-94dd5484afbe', 'processed', now()),  -- Wecasa
  ('business_client', '0983ac51-4316-4491-97af-928858e4f564', 'companies', 'b6920cf1-65d6-5822-a980-94dd5484afbe', 'processed', now()),  -- Wecasa Wellness
  ('business_client', 'a03d189a-922b-4a12-bdde-3c215f6420d6', 'companies', '9c75aec6-9245-4873-9ba3-4ddbcdfedcdc', 'processed', now()),  -- Withings
  ('business_client', 'c31f053c-ca1a-4f34-a7b7-a12814fef8d3', 'companies', 'd1e96737-b6d7-498c-a0c1-803ab818547f', 'processed', now()),  -- WWWatch
  ('business_client', '1f7b10a8-504f-4487-95dc-f6750e8fe9b5', 'companies', '43620919-79d8-4441-8651-469c3d898e62', 'processed', now()),  -- Élhée
  ('business_client', 'd112b93a-d6b1-4c3a-b160-415959fd4c5b', 'companies', 'c6a55a05-f5c6-4a0e-b5e8-9432841188d3', 'processed', now())  -- Ôdass Paris
on conflict (source, external_id) do update
  set attio_record_id = excluded.attio_record_id, attio_object_type = excluded.attio_object_type, processed_at = now();
