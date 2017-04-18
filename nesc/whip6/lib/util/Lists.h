/*
 * Copyright (c) 1991, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *
 * whip6: Warsaw High-performance IPv6.
 *
 * Copyright (c) 2012-2017 Szymon Acedanski
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached LICENSE     
 * files.
 */

#ifndef _LISTS_H_INCLUDED
#define _LISTS_H_INCLUDED

/*
 * This file defines five types of data structures: singly-linked lists,
 * singly-linked tail queues, lists, tail queues, and circular queues.
 *
 * A singly-linked list is headed by a single forward pointer. The elements
 * are singly linked for minimum space and pointer manipulation overhead at
 * the expense of O(n) removal for arbitrary elements. New elements can be
 * added to the list after an existing element or at the head of the list.
 * Elements being removed from the head of the list should use the explicit
 * macro for this purpose for optimum efficiency. A singly-linked list may
 * only be traversed in the forward direction.  Singly-linked lists are ideal
 * for applications with large datasets and few or no removals or for
 * implementing a LIFO queue.
 *
 * A singly-linked tail queue is headed by a pair of pointers, one to the
 * head of the list and the other to the tail of the list. The elements are
 * singly linked for minimum space and pointer manipulation overhead at the
 * expense of O(n) removal for arbitrary elements. New elements can be added
 * to the list after an existing element, at the head of the list, or at the
 * end of the list. Elements being removed from the head of the tail queue
 * should use the explicit macro for this purpose for optimum efficiency.
 * A singly-linked tail queue may only be traversed in the forward direction.
 * Singly-linked tail queues are ideal for applications with large datasets
 * and few or no removals or for implementing a FIFO queue.
 *
 * A list is headed by a single forward pointer (or an array of forward
 * pointers for a hash table header). The elements are doubly linked
 * so that an arbitrary element can be removed without a need to
 * traverse the list. New elements can be added to the list before
 * or after an existing element or at the head of the list. A list
 * may only be traversed in the forward direction.
 *
 * A tail queue is headed by a pair of pointers, one to the head of the
 * list and the other to the tail of the list. The elements are doubly
 * linked so that an arbitrary element can be removed without a need to
 * traverse the list. New elements can be added to the list before or
 * after an existing element, at the head of the list, or at the end of
 * the list. A tail queue may be traversed in either direction.
 *
 * A circle queue is headed by a pair of pointers, one to the head of the
 * list and the other to the tail of the list. The elements are doubly
 * linked so that an arbitrary element can be removed without a need to
 * traverse the list. New elements can be added to the list before or after
 * an existing element, at the head of the list, or at the end of the list.
 * A circle queue may be traversed in either direction, but has a more
 * complex end of list detection.
 *
 * For details on the use of these macros, see the queue(3) manual page.
 *
 *
 *                      WHIP6_LIST_SLIST   WHIP6_LIST_LIST    WHIP6_LIST_STAILQ  WHIP6_LIST_TAILQ   WHIP6_LIST_CIRCLEQ
 * _HEAD                +       +       +       +       +
 * _HEAD_INITIALIZER    +       +       +       +       +
 * _ENTRY               +       +       +       +       +
 * _INIT                +       +       +       +       +
 * _EMPTY               +       +       +       +       +
 * _FIRST               +       +       +       +       +
 * _NEXT                +       +       +       +       +
 * _PREV                -       -       -       +       +
 * _LAST                -       -       +       +       +
 * _FOREACH             +       +       +       +       +
 * _FOREACH_REVERSE     -       -       -       +       +
 * _INSERT_HEAD         +       +       +       +       +
 * _INSERT_BEFORE       -       +       -       +       +
 * _INSERT_AFTER        +       +       +       +       +
 * _INSERT_TAIL         -       -       +       +       +
 * _REMOVE_HEAD         +       -       +       -       -
 * _REMOVE              +       +       +       +       +
 *
 */

/*
 * Singly-linked List declarations.
 */
#define WHIP6_LIST_SLIST_HEAD(name, type)                          \
struct name {                                           \
    type *slh_first;	/* first element */         \
}

#define WHIP6_LIST_SLIST_HEAD_INITIALIZER(head)                    \
    { NULL }

#define WHIP6_LIST_SLIST_ENTRY(type)                               \
struct {                                                \
    type *sle_next;  /* next element */          \
}

/*
 * Singly-linked List functions.
 */
#define WHIP6_LIST_SLIST_EMPTY(head)   ((head)->slh_first == NULL)

#define WHIP6_LIST_SLIST_FIRST(head)   ((head)->slh_first)

#define WHIP6_LIST_SLIST_FOREACH(var, head, field)                 \
    for ((var) = WHIP6_LIST_SLIST_FIRST((head));                   \
        (var);                                          \
        (var) = WHIP6_LIST_SLIST_NEXT((var), field))

#define WHIP6_LIST_SLIST_INIT(head) do {                           \
        WHIP6_LIST_SLIST_FIRST((head)) = NULL;                     \
} while (0)

#define WHIP6_LIST_SLIST_INSERT_AFTER(slistelm, elm, field) do {           \
    WHIP6_LIST_SLIST_NEXT((elm), field) = WHIP6_LIST_SLIST_NEXT((slistelm), field);   \
    WHIP6_LIST_SLIST_NEXT((slistelm), field) = (elm);                      \
} while (0)

#define WHIP6_LIST_SLIST_INSERT_HEAD(head, elm, field) do {            \
    WHIP6_LIST_SLIST_NEXT((elm), field) = WHIP6_LIST_SLIST_FIRST((head));         \
    WHIP6_LIST_SLIST_FIRST((head)) = (elm);                            \
} while (0)

#define WHIP6_LIST_SLIST_NEXT(elm, field)	((elm)->field.sle_next)

#define WHIP6_LIST_SLIST_REMOVE(head, elm, type, field) do {           \
    if (WHIP6_LIST_SLIST_FIRST((head)) == (elm)) {                     \
        WHIP6_LIST_SLIST_REMOVE_HEAD((head), field);                   \
    }                                                       \
    else {                                                  \
        type *curelm = WHIP6_LIST_SLIST_FIRST((head));          \
        while (WHIP6_LIST_SLIST_NEXT(curelm, field) != (elm))          \
            curelm = WHIP6_LIST_SLIST_NEXT(curelm, field);             \
        WHIP6_LIST_SLIST_NEXT(curelm, field) =                         \
            WHIP6_LIST_SLIST_NEXT(WHIP6_LIST_SLIST_NEXT(curelm, field), field);   \
    }                                                       \
} while (0)

#define WHIP6_LIST_SLIST_REMOVE_HEAD(head, field) do {                         \
    WHIP6_LIST_SLIST_FIRST((head)) = WHIP6_LIST_SLIST_NEXT(WHIP6_LIST_SLIST_FIRST((head)), field);   \
} while (0)

/*
 * Singly-linked Tail queue declarations.
 */
#define WHIP6_LIST_STAILQ_HEAD(name, type)						\
struct name {								\
	type *stqh_first;/* first element */			\
	type **stqh_last;/* addr of last next element */		\
}

#define WHIP6_LIST_STAILQ_HEAD_INITIALIZER(head)					\
	{ NULL, &(head).stqh_first }

#define WHIP6_LIST_STAILQ_ENTRY(type)						\
struct {								\
	type *stqe_next;	/* next element */			\
}

/*
 * Singly-linked Tail queue functions.
 */
#define WHIP6_LIST_STAILQ_EMPTY(head)	((head)->stqh_first == NULL)

#define WHIP6_LIST_STAILQ_FIRST(head)	((head)->stqh_first)

#define WHIP6_LIST_STAILQ_FOREACH(var, head, field)				\
	for((var) = WHIP6_LIST_STAILQ_FIRST((head));				\
	   (var);							\
	   (var) = WHIP6_LIST_STAILQ_NEXT((var), field))

#define WHIP6_LIST_STAILQ_INIT(head) do {						\
	WHIP6_LIST_STAILQ_FIRST((head)) = NULL;					\
	(head)->stqh_last = &WHIP6_LIST_STAILQ_FIRST((head));			\
} while (0)

#define WHIP6_LIST_STAILQ_INSERT_AFTER(head, tqelm, elm, field) do {		\
	if ((WHIP6_LIST_STAILQ_NEXT((elm), field) = WHIP6_LIST_STAILQ_NEXT((tqelm), field)) == NULL)\
		(head)->stqh_last = &WHIP6_LIST_STAILQ_NEXT((elm), field);		\
	WHIP6_LIST_STAILQ_NEXT((tqelm), field) = (elm);				\
} while (0)

#define WHIP6_LIST_STAILQ_INSERT_HEAD(head, elm, field) do {			\
	if ((WHIP6_LIST_STAILQ_NEXT((elm), field) = WHIP6_LIST_STAILQ_FIRST((head))) == NULL)	\
		(head)->stqh_last = &WHIP6_LIST_STAILQ_NEXT((elm), field);		\
	WHIP6_LIST_STAILQ_FIRST((head)) = (elm);					\
} while (0)

#define WHIP6_LIST_STAILQ_INSERT_TAIL(head, elm, field) do {			\
	WHIP6_LIST_STAILQ_NEXT((elm), field) = NULL;				\
	*(head)->stqh_last = (elm);					\
	(head)->stqh_last = &WHIP6_LIST_STAILQ_NEXT((elm), field);			\
} while (0)

#define WHIP6_LIST_STAILQ_LAST(head, type, field)					\
	(WHIP6_LIST_STAILQ_EMPTY(head) ?						\
		NULL :							\
	        ((type *)					\
		((char *)((head)->stqh_last) - offsetof(type, field))))

#define WHIP6_LIST_STAILQ_NEXT(elm, field)	((elm)->field.stqe_next)

#define WHIP6_LIST_STAILQ_REMOVE(head, elm, type, field) do {			\
	if (WHIP6_LIST_STAILQ_FIRST((head)) == (elm)) {				\
		WHIP6_LIST_STAILQ_REMOVE_HEAD(head, field);			\
	}								\
	else {								\
		type *curelm = WHIP6_LIST_STAILQ_FIRST((head));		\
		while (WHIP6_LIST_STAILQ_NEXT(curelm, field) != (elm))		\
			curelm = WHIP6_LIST_STAILQ_NEXT(curelm, field);		\
		if ((WHIP6_LIST_STAILQ_NEXT(curelm, field) =			\
		     WHIP6_LIST_STAILQ_NEXT(WHIP6_LIST_STAILQ_NEXT(curelm, field), field)) == NULL)\
			(head)->stqh_last = &WHIP6_LIST_STAILQ_NEXT((curelm), field);\
	}								\
} while (0)

#define WHIP6_LIST_STAILQ_REMOVE_HEAD(head, field) do {				\
	if ((WHIP6_LIST_STAILQ_FIRST((head)) =					\
	     WHIP6_LIST_STAILQ_NEXT(WHIP6_LIST_STAILQ_FIRST((head)), field)) == NULL)		\
		(head)->stqh_last = &WHIP6_LIST_STAILQ_FIRST((head));		\
} while (0)

#define WHIP6_LIST_STAILQ_REMOVE_HEAD_UNTIL(head, elm, field) do {			\
	if ((WHIP6_LIST_STAILQ_FIRST((head)) = WHIP6_LIST_STAILQ_NEXT((elm), field)) == NULL)	\
		(head)->stqh_last = &WHIP6_LIST_STAILQ_FIRST((head));		\
} while (0)

#define WHIP6_LIST_STAILQ_REMOVE_AFTER(head, elm, field) do {			\
	if ((WHIP6_LIST_STAILQ_NEXT(elm, field) =					\
	     WHIP6_LIST_STAILQ_NEXT(WHIP6_LIST_STAILQ_NEXT(elm, field), field)) == NULL)	\
		(head)->stqh_last = &WHIP6_LIST_STAILQ_NEXT((elm), field);		\
} while (0)

/*
 * List declarations.
 */
#define WHIP6_LIST_LIST_HEAD(name, type)						\
struct name {								\
	type *lh_first;	/* first element */			\
}

#define WHIP6_LIST_LIST_HEAD_INITIALIZER(head)					\
	{ NULL }

#define WHIP6_LIST_LIST_ENTRY(type)						\
struct {								\
	type *le_next;	/* next element */			\
	type **le_prev;	/* address of previous next element */	\
}

/*
 * List functions.
 */

#define WHIP6_LIST_LIST_EMPTY(head)	((head)->lh_first == NULL)

#define WHIP6_LIST_LIST_FIRST(head)	((head)->lh_first)

#define WHIP6_LIST_LIST_FOREACH(var, head, field)					\
	for ((var) = WHIP6_LIST_LIST_FIRST((head));				\
	    (var);							\
	    (var) = WHIP6_LIST_LIST_NEXT((var), field))

#define WHIP6_LIST_LIST_INIT(head) do {						\
	WHIP6_LIST_LIST_FIRST((head)) = NULL;					\
} while (0)

#define WHIP6_LIST_LIST_INSERT_AFTER(listelm, elm, field) do {			\
	if ((WHIP6_LIST_LIST_NEXT((elm), field) = WHIP6_LIST_LIST_NEXT((listelm), field)) != NULL)\
		WHIP6_LIST_LIST_NEXT((listelm), field)->field.le_prev =		\
		    &WHIP6_LIST_LIST_NEXT((elm), field);				\
	WHIP6_LIST_LIST_NEXT((listelm), field) = (elm);				\
	(elm)->field.le_prev = &WHIP6_LIST_LIST_NEXT((listelm), field);		\
} while (0)

#define WHIP6_LIST_LIST_INSERT_BEFORE(listelm, elm, field) do {			\
	(elm)->field.le_prev = (listelm)->field.le_prev;		\
	WHIP6_LIST_LIST_NEXT((elm), field) = (listelm);				\
	*(listelm)->field.le_prev = (elm);				\
	(listelm)->field.le_prev = &WHIP6_LIST_LIST_NEXT((elm), field);		\
} while (0)

#define WHIP6_LIST_LIST_INSERT_HEAD(head, elm, field) do {				\
	if ((WHIP6_LIST_LIST_NEXT((elm), field) = WHIP6_LIST_LIST_FIRST((head))) != NULL)	\
		WHIP6_LIST_LIST_FIRST((head))->field.le_prev = &WHIP6_LIST_LIST_NEXT((elm), field);\
	WHIP6_LIST_LIST_FIRST((head)) = (elm);					\
	(elm)->field.le_prev = &WHIP6_LIST_LIST_FIRST((head));			\
} while (0)

#define WHIP6_LIST_LIST_NEXT(elm, field)	((elm)->field.le_next)

#define WHIP6_LIST_LIST_REMOVE(elm, field) do {					\
	if (WHIP6_LIST_LIST_NEXT((elm), field) != NULL)				\
		WHIP6_LIST_LIST_NEXT((elm), field)->field.le_prev = 		\
		    (elm)->field.le_prev;				\
	*(elm)->field.le_prev = WHIP6_LIST_LIST_NEXT((elm), field);		\
} while (0)

/*
 * Tail queue declarations.
 */
#define WHIP6_LIST_TAILQ_HEAD(name, type)						\
struct name {								\
	type *tqh_first;	/* first element */			\
	type **tqh_last;	/* addr of last next element */		\
}

#define WHIP6_LIST_TAILQ_HEAD_INITIALIZER(head)					\
	{ NULL, &(head).tqh_first }

#define WHIP6_LIST_TAILQ_ENTRY(type)						\
struct {								\
	type *tqe_next;	/* next element */			\
	type **tqe_prev;	/* address of previous next element */	\
}

/*
 * Tail queue functions.
 */
#define WHIP6_LIST_TAILQ_EMPTY(head)	((head)->tqh_first == NULL)

#define WHIP6_LIST_TAILQ_FIRST(head)	((head)->tqh_first)

#define WHIP6_LIST_TAILQ_FOREACH(var, head, field)					\
	for ((var) = WHIP6_LIST_TAILQ_FIRST((head));				\
	    (var);							\
	    (var) = WHIP6_LIST_TAILQ_NEXT((var), field))

#define WHIP6_LIST_TAILQ_FOREACH_REVERSE(var, head, headname, field)		\
	for ((var) = WHIP6_LIST_TAILQ_LAST((head), headname);			\
	    (var);							\
	    (var) = WHIP6_LIST_TAILQ_PREV((var), headname, field))

#define WHIP6_LIST_TAILQ_INIT(head) do {						\
	WHIP6_LIST_TAILQ_FIRST((head)) = NULL;					\
	(head)->tqh_last = &WHIP6_LIST_TAILQ_FIRST((head));			\
} while (0)

#define WHIP6_LIST_TAILQ_INSERT_AFTER(head, listelm, elm, field) do {		\
	if ((WHIP6_LIST_TAILQ_NEXT((elm), field) = WHIP6_LIST_TAILQ_NEXT((listelm), field)) != NULL)\
		WHIP6_LIST_TAILQ_NEXT((elm), field)->field.tqe_prev = 		\
		    &WHIP6_LIST_TAILQ_NEXT((elm), field);				\
	else								\
		(head)->tqh_last = &WHIP6_LIST_TAILQ_NEXT((elm), field);		\
	WHIP6_LIST_TAILQ_NEXT((listelm), field) = (elm);				\
	(elm)->field.tqe_prev = &WHIP6_LIST_TAILQ_NEXT((listelm), field);		\
} while (0)

#define WHIP6_LIST_TAILQ_INSERT_BEFORE(listelm, elm, field) do {			\
	(elm)->field.tqe_prev = (listelm)->field.tqe_prev;		\
	WHIP6_LIST_TAILQ_NEXT((elm), field) = (listelm);				\
	*(listelm)->field.tqe_prev = (elm);				\
	(listelm)->field.tqe_prev = &WHIP6_LIST_TAILQ_NEXT((elm), field);		\
} while (0)

#define WHIP6_LIST_TAILQ_INSERT_HEAD(head, elm, field) do {			\
	if ((WHIP6_LIST_TAILQ_NEXT((elm), field) = WHIP6_LIST_TAILQ_FIRST((head))) != NULL)	\
		WHIP6_LIST_TAILQ_FIRST((head))->field.tqe_prev =			\
		    &WHIP6_LIST_TAILQ_NEXT((elm), field);				\
	else								\
		(head)->tqh_last = &WHIP6_LIST_TAILQ_NEXT((elm), field);		\
	WHIP6_LIST_TAILQ_FIRST((head)) = (elm);					\
	(elm)->field.tqe_prev = &WHIP6_LIST_TAILQ_FIRST((head));			\
} while (0)

#define WHIP6_LIST_TAILQ_INSERT_TAIL(head, elm, field) do {			\
	WHIP6_LIST_TAILQ_NEXT((elm), field) = NULL;				\
	(elm)->field.tqe_prev = (head)->tqh_last;			\
	*(head)->tqh_last = (elm);					\
	(head)->tqh_last = &WHIP6_LIST_TAILQ_NEXT((elm), field);			\
} while (0)

#define WHIP6_LIST_TAILQ_LAST(head, headname)					\
	(*(((headname *)((head)->tqh_last))->tqh_last))

#define WHIP6_LIST_TAILQ_NEXT(elm, field) ((elm)->field.tqe_next)

#define WHIP6_LIST_TAILQ_PREV(elm, headname, field)				\
	(*(((headname *)((elm)->field.tqe_prev))->tqh_last))

#define WHIP6_LIST_TAILQ_REMOVE(head, elm, field) do {				\
	if ((WHIP6_LIST_TAILQ_NEXT((elm), field)) != NULL)				\
		WHIP6_LIST_TAILQ_NEXT((elm), field)->field.tqe_prev = 		\
		    (elm)->field.tqe_prev;				\
	else								\
		(head)->tqh_last = (elm)->field.tqe_prev;		\
	*(elm)->field.tqe_prev = WHIP6_LIST_TAILQ_NEXT((elm), field);		\
} while (0)

/*
 * Circular queue declarations.
 */
#define WHIP6_LIST_CIRCLEQ_HEAD(name, type)					\
struct name {								\
	type *cqh_first;		/* first element */		\
	type *cqh_last;		/* last element */		\
}

#define WHIP6_LIST_CIRCLEQ_HEAD_INITIALIZER(head)					\
	{ (void *)&(head), (void *)&(head) }

#define WHIP6_LIST_CIRCLEQ_ENTRY(type)						\
struct {								\
	type *cqe_next;		/* next element */		\
	type *cqe_prev;		/* previous element */		\
}

/*
 * Circular queue functions.
 */
#define WHIP6_LIST_CIRCLEQ_EMPTY(head)	((head)->cqh_first == (void *)(head))

#define WHIP6_LIST_CIRCLEQ_FIRST(head)	((head)->cqh_first)

#define WHIP6_LIST_CIRCLEQ_FOREACH(var, head, field)				\
	for ((var) = WHIP6_LIST_CIRCLEQ_FIRST((head));				\
	    (var) != (void *)(head) || ((var) = NULL);			\
	    (var) = WHIP6_LIST_CIRCLEQ_NEXT((var), field))

#define WHIP6_LIST_CIRCLEQ_FOREACH_REVERSE(var, head, field)			\
	for ((var) = WHIP6_LIST_CIRCLEQ_LAST((head));				\
	    (var) != (void *)(head) || ((var) = NULL);			\
	    (var) = WHIP6_LIST_CIRCLEQ_PREV((var), field))

#define WHIP6_LIST_CIRCLEQ_INIT(head) do {						\
	WHIP6_LIST_CIRCLEQ_FIRST((head)) = (void *)(head);				\
	WHIP6_LIST_CIRCLEQ_LAST((head)) = (void *)(head);				\
} while (0)

#define WHIP6_LIST_CIRCLEQ_INSERT_AFTER(head, listelm, elm, field) do {		\
	WHIP6_LIST_CIRCLEQ_NEXT((elm), field) = WHIP6_LIST_CIRCLEQ_NEXT((listelm), field);	\
	WHIP6_LIST_CIRCLEQ_PREV((elm), field) = (listelm);				\
	if (WHIP6_LIST_CIRCLEQ_NEXT((listelm), field) == (void *)(head))		\
		WHIP6_LIST_CIRCLEQ_LAST((head)) = (elm);				\
	else								\
		WHIP6_LIST_CIRCLEQ_PREV(WHIP6_LIST_CIRCLEQ_NEXT((listelm), field), field) = (elm);\
	WHIP6_LIST_CIRCLEQ_NEXT((listelm), field) = (elm);				\
} while (0)

#define WHIP6_LIST_CIRCLEQ_INSERT_BEFORE(head, listelm, elm, field) do {		\
	WHIP6_LIST_CIRCLEQ_NEXT((elm), field) = (listelm);				\
	WHIP6_LIST_CIRCLEQ_PREV((elm), field) = WHIP6_LIST_CIRCLEQ_PREV((listelm), field);	\
	if (WHIP6_LIST_CIRCLEQ_PREV((listelm), field) == (void *)(head))		\
		WHIP6_LIST_CIRCLEQ_FIRST((head)) = (elm);				\
	else								\
		WHIP6_LIST_CIRCLEQ_NEXT(WHIP6_LIST_CIRCLEQ_PREV((listelm), field), field) = (elm);\
	WHIP6_LIST_CIRCLEQ_PREV((listelm), field) = (elm);				\
} while (0)

#define WHIP6_LIST_CIRCLEQ_INSERT_HEAD(head, elm, field) do {			\
	WHIP6_LIST_CIRCLEQ_NEXT((elm), field) = WHIP6_LIST_CIRCLEQ_FIRST((head));		\
	WHIP6_LIST_CIRCLEQ_PREV((elm), field) = (void *)(head);			\
	if (WHIP6_LIST_CIRCLEQ_LAST((head)) == (void *)(head))			\
		WHIP6_LIST_CIRCLEQ_LAST((head)) = (elm);				\
	else								\
		WHIP6_LIST_CIRCLEQ_PREV(WHIP6_LIST_CIRCLEQ_FIRST((head)), field) = (elm);	\
	WHIP6_LIST_CIRCLEQ_FIRST((head)) = (elm);					\
} while (0)

#define WHIP6_LIST_CIRCLEQ_INSERT_TAIL(head, elm, field) do {			\
	WHIP6_LIST_CIRCLEQ_NEXT((elm), field) = (void *)(head);			\
	WHIP6_LIST_CIRCLEQ_PREV((elm), field) = WHIP6_LIST_CIRCLEQ_LAST((head));		\
	if (WHIP6_LIST_CIRCLEQ_FIRST((head)) == (void *)(head))			\
		WHIP6_LIST_CIRCLEQ_FIRST((head)) = (elm);				\
	else								\
		WHIP6_LIST_CIRCLEQ_NEXT(WHIP6_LIST_CIRCLEQ_LAST((head)), field) = (elm);	\
	WHIP6_LIST_CIRCLEQ_LAST((head)) = (elm);					\
} while (0)

#define WHIP6_LIST_CIRCLEQ_LAST(head)	((head)->cqh_last)

#define WHIP6_LIST_CIRCLEQ_NEXT(elm,field)	((elm)->field.cqe_next)

#define WHIP6_LIST_CIRCLEQ_PREV(elm,field)	((elm)->field.cqe_prev)

#define WHIP6_LIST_CIRCLEQ_REMOVE(head, elm, field) do {				\
	if (WHIP6_LIST_CIRCLEQ_NEXT((elm), field) == (void *)(head))		\
		WHIP6_LIST_CIRCLEQ_LAST((head)) = WHIP6_LIST_CIRCLEQ_PREV((elm), field);	\
	else								\
		WHIP6_LIST_CIRCLEQ_PREV(WHIP6_LIST_CIRCLEQ_NEXT((elm), field), field) =	\
		    WHIP6_LIST_CIRCLEQ_PREV((elm), field);				\
	if (WHIP6_LIST_CIRCLEQ_PREV((elm), field) == (void *)(head))		\
		WHIP6_LIST_CIRCLEQ_FIRST((head)) = WHIP6_LIST_CIRCLEQ_NEXT((elm), field);	\
	else								\
		WHIP6_LIST_CIRCLEQ_NEXT(WHIP6_LIST_CIRCLEQ_PREV((elm), field), field) =	\
		    WHIP6_LIST_CIRCLEQ_NEXT((elm), field);				\
} while (0)

#endif /* !_LISTS_H_INCLUDED */
