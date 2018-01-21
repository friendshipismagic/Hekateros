# Hécatéros

>Dieu de l'hécatéris, danse utilisant rapidement les mains…

* [Les tags](#les-tags)
* [Configuration](#configuration)
* [TODO](#todo)

AVERTISSEMENT: En l'état, ce programme est tout sauf prêt à être utilisé de façon pérenne. Chaque commit va changer un comportement, fixer un bug et en
introduire d'autres. BEWARE.

Hécatéros repose sur un canal IRC et récupère les liens qui y sont posté. Il affiche une interface web pour les parcourir.

Pour plus de *privacy*, les URL des canaux dans l'interface web ne seront pas nominatives mais seront de la forme
`https://hecateros.example.org/c/UUID`.


## Les tags

Pour mieux aider à catégoriser les liens postés, un système de tags est disponible (ou bientôt disponible, suivant votre continuum spatio-temporel).

* Soit le bot prend ce qu'il trouve comme tags et les ajoute à sa base de données.
* Soit le bot fait correspondre les tags à une liste pré-définie (mais extensible) et dans ce cas-là refusera poliment les tags non-conformes mais prendra
    les bons tags.

Cela permettra une recherche par tags dans l'interface web, voir une commande spéciale pour faire apparaître les 5 derniers liens correspondant à tel tag.

Les tags sont insensibles à la casse et idéalement ne comporteraient qu'un seul mot.

Exemples de syntaxe possible :

1. `< Theophane> https://example.org #exemple,w3c#`
2. `< Theophane> Hey checkez ce lien : https://example.org/foobarlol #exemple, w3c#`

Possible façon de faire pour les URL sans tags: 

1. Soit on la stock pas.
2. Soit on la stock sans tags, et si elle réapparaît avec tags, on met juste à jour les tags.


## Configuration

Les fichiers de configuration se situent dans le dossier `config/` à la racine du projet.  
Il est prévu de pouvoir y inclure plusieurs options comme ajouter ou retirer un prefix de protocol, ou d'empêcher certains liens
(sourcer un fichier de blacklist ?). Ces options-là seront également fournies au runtime par les fonctions appropriées.

## Déploiement

Un dossier `deploy` fourni un playbook Ansible avec le template et les fichiers de configuration utilisés. Le fichier `hosts` utilisé doit exporter la
variable `public_inteface` qui correspond à l'adresse sur laquelle Nginx va écouter.

## TODO

- Core
  - [ ] update des tags associés à un lien si repost en moins de 30s
- IRC
  - [ ] Envoyer un message à `Whois`, puis recevoir la réponse dans `Whois` et l'envoyer à `Channel` qui va à partir de là continuer le processus d'auth.
  - [ ] Remplacer le champs "nick" de l'Admin par "username"

