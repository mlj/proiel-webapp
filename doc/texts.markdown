Gothic
------

The Gothic text is based on that of [wulfila.be](http://www.wulfila.be/gothic/). 
The Titus Gothic text has also been transcoded as a result of early experimentation.

Below are some notes from the conversion process for wulfila.be.

#### Text

The text includes multiple witnesses with significant overlap between these.

#### Lemmatisation

The lemmatisation is based entirely on Streitberg's dictionary as prepared by
wulfila.be. A couple of conventions of Streitberg's are important to keep in mind.

  * The notation _innatgāhts*_ indicates reconstructed forms.
  * The notation _*seins_ indicates hypothetical forms. In fact, this only seems
    to occur for _seins_, and wulfila.be's electronic version of the dictionary
    fails to indicate this.
  * The notation _†Aai_ indicates a conjecture (_besserungsbedürftig_). (The dagger
    symbol, when reproduced by PROIEL, is mapped to `U+2020`.)

wulfila.be has opted to use a different lemma than Streitberg for roughly 100
lemmata. These can be found by comparing `Lemma.lemma` and `Lemma.WSLemma` in wulfila.be's
database. Below are listed all such lemmata, divided into classes according to how
this has been dealt with in the PROIEL transfer.

##### Diacritics

  * andaþahts, andaþāhts
  * hahan, hāhan
  * gudhus, gudhūs
  * haihs, háihs
  * haiþno, háiþno
  * hauhs, háuhs
  * hlutrs, hlūtrs                         (→ hlūtrs*)
  * hrukjan, hrūkjan
  * jus, jūs
  * juzei, jūzei
  * innatgahts, innatgāhts                 (→ innatgāhts*)
  * galeikon, gáleikon
  * ga-galeikon, ga-gáleikon
  * in-galeikon, in-gáleikon
  * miþ-galeikon, miþ-gáleikon
  * þairh-galeikon, þairh-gáleikon
  * ga-lukan, ga-lūkan
  * gamainjan, gámainjan
  * ga-gamainjan, ga-gámainjan
  * managduþs, managdūþs
  * mikilduþs, mikildūþs
  * faur-muljan, faur-mūljan
  * garaihtjan, gáraihtjan
  * at-garaihtjan, at-gáraihtjan
  * ga-gahaftjan, ga-gáhaftjan
  * hraiwadubo, hraiwadūbo
  * rumis, rūmis
  * Ruma, Rūma
  * ur-rumnan, ur-rūmnan
  * Rumoneis, Rūmoneis                    (→ Rūmoneis*)
  * rums, rūms
  * runa, rūna
  * sair, sáir
  * skura, skūra
  * ga-gatilon, ga-gátilon
  * þaho, þāho
  * ga-þlaihan, ga-þláihan
  * þrutsfill, þrūtsfill
  * þusundi, þūsundi
  * unatgahts, unatgāhts
  * unbruks, unbrūks
  * ut, ūt
  * uta, ūta
  * utana, ūtana
  * utaþro, ūtaþro
  * waila, wáila
  * ga-gawairþjan, ga-gáwairþjan
  * ga-gawairþnan, ga-gáwairþnan

We have reverted to the Streitberg forms in all these cases.

The following cases are somewhat puzzling; Streitberg has the forms without quantity, so does wulfila.be's
electronic version. Again the Streitberg form has been used.

  * us-lukan, &lt;us-lūkan&gt;
  * þrutsfills, &lt;þrūtsfills&gt;
  * þusundifaþs, &lt;þūsundifaþs&gt;
  * hlutrei, &lt;hlūtrei&gt;
  * hlutriþa, &lt;hlūtriþa&gt;

##### Various

  * laian, &lt;multi&gt;o. lauan* → laian*

    Streitberg and electronic dictionary: _laian* o. lauan_

##### Unresolved

TODO: dunno what to do about these yet and have not verified them

  * Ananias, Ananias* u. Ananeias*
  * diabaulus, diabaulus u. diabulus
  * paska, paska u. pasxa
  * paurpura, paurpura u. paurpaura
  * Iudaius, Iudaius u. Judaius

  * Klemaintau, Klemaintau B u. Klaimaintau A
  * swartiza, swartiza (A) u. swartizla (B)

  * alamans, alamans* o. alamannans
  * izei, izei o. ize

  * Alul, [Alul] Αλουλ oder [Ailul] Ελουλ
  * ams, &lt;multi&gt;oder amsa* Mn
  * Antiaukia, Antiaukia*, Antiokia*
  * Ater, Ater*, Ateir*
  * aurkje, &lt;multi&gt;aurkjus oder aurkeis* Mia
  * auþeis, &lt;multi&gt;oder auþs*
  * bistugq, bistug(g)q
  * faus, fawai
  * af-giban, af-giban sik
  * hnasqus, hnasqjaim
  * Iaireiko, Iaireiko*, Iairiko*
  * ibnaskauns, &lt;multi&gt;oder -skauneis* ia(182 II)
  * is, is M, si F, ita N
  * nibai,  nibai, niba
  * reikeis,  &lt;multi&gt;o. reiks* i/ja (183)
  * riureis,  &lt;multi&gt;o. riurs* Adj.i/ja (183)
  * uf-saggqjan,  uf-saggqjan A und uf-saggqjan B (28b)
  * seins, *seins
  * dis-sigqan,dis-sig(g)qan
  * skauns,  &lt;multi&gt;oder skauneis* (182II)
  * skeirs,  &lt;multi&gt;o. i/ja (183(2))
  * sleiþs,  &lt;multi&gt;o. sleideis* (182 II)
  * ga-stigqan,ga-stiggqan
  * sutis,  &lt;multi&gt;o. ia (182 II)
  * suþjan,  &lt;multi&gt;o. suþjon sw.V.2
  * unriureis,  &lt;multi&gt;o. unriurs* Adj.i/ja (183)
  * usbloteins, us-bloteins
  * war, warai
  * and-weihan, and-waihan*
