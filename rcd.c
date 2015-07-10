/*-
 * Copyright (c) 2007 Wojciech A. Koszek <wkoszek@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $Id$
 */
#include <sys/types.h>
#include <sys/stat.h>

#include <assert.h>
#include <err.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sysexits.h>
#include <unistd.h>

/*
 * Sample usage of this simple program.
 */
static void
usage(const char *progname)
{
	fprintf(stderr, "%s inputfile\n", progname);
	exit(EX_USAGE);
}

/*
 * Structure holding IP addresses to be mapped to anonymous names.
 */
struct ip {
	int		ip0, ip1, ip2, ip3;
	char		*desc;
	struct ip	*next;
};

/*
 * Global list of all IP addresses available.
 */
static struct ip *ips = NULL;

/*
 * Inserts detected IP to the global list.
 */
static int
ipinsert(int a, int b, int c, int d)
{
	struct ip *new;

	new = calloc(1, sizeof(struct ip));
	assert(new != NULL);
	new->ip0 = a;
	new->ip1 = b;
	new->ip2 = c;
	new->ip3 = d;
	new->next = ips;
	ips = new;
	return (0);
}

/*
 * Searches IP address in a global list.
 * Returns element if it exists or NULL otherwise.
 */
static struct ip *
ipfind(int a, int b, int c, int d)
{
	struct ip *p;
	int r;

	for (p = ips; p != NULL; p = p->next) {
		r = 0;
		if (p->ip0 == a)
			r++;
		if (p->ip1 == b)
			r++;
		if (p->ip2 == c)
			r++;
		if (p->ip3 == d)
			r++;
		if (r == 4)
			return (p);
	}
	return (NULL);
}

/*
 * Creates mapping from valid IP address to anonymous mapping.
 */
static void
ipmapcreate(void)
{
	struct ip *iter;
	char *desc;
	int a, b, c, d;

	iter = ips;
	for (a = 'a'; a < 'z'; a++)
		for (b = 'a'; b < 'z'; b++)
			for (c = 'a'; c < 'z'; c++)
				for (d = 'a'; d < 'z'; d++) {
					if (iter != NULL) {
						asprintf(&desc, "%c.%c.%c.%c",
						    a, b, c, d);
						assert(desc != NULL);
						iter->desc = desc;
						iter = iter->next;
					} else
						return;
				}
}

/*
 * Dumps sed(1) script.
 */
static void
ipdump(void)
{
	struct ip *i;

	printf("#!/bin/sh\n");
	printf("sed '");
	for (i = ips; i != NULL; i = i->next) {
		printf("s/%d.%d.%d.%d/%s/g;\n", i->ip0, i->ip1, i->ip2, i->ip3,
		    i->desc);
	}
	printf("'\n");
}

/*
 * This simple program might be useful to hide confidentian data from the
 * other people eyes once you find a need to publicate your file in the
 * Internet.
 *
 * First argument is a file name, where IP addresses to be masked are placed.
 * The sed(1) script will be printed on the standard output. You have to use
 * it in order to do actual conversion. This is useful, as some people might
 * want to change some IP addresses to fixed mapping.. (...which should be
 * really implemented somewhere here..).
 */
int
main (int argc, char **argv)
{
	int ip0, ip1, ip2, ip3, fin, r, tab;
	char *line, *buf, *b, *bufin, *ap;
	struct ip *isnew;
	struct stat st;

	if (argc < 2)
		usage(argv[0]);
	fin = open(argv[1], O_RDONLY);
	if (fin == -1)
		err(EXIT_FAILURE, "Couldn't open file %s\n", argv[1]);
	if (fstat(fin, &st) != 0)
		err(EXIT_FAILURE, "Couldn't fstat() input descriptor");
	bufin = malloc(st.st_size);
	if (bufin == NULL)
		err(EXIT_FAILURE, "Couldn't allocate memory");
	bzero(bufin, st.st_size);
	r = read(fin, bufin, st.st_size);
	assert(r == st.st_size);
	while ((line = strsep(&bufin, "\n")) != NULL) {
		buf = b = strdup(line);
		assert(buf != NULL);
		for (;;) {
			if (buf == NULL)
				break;
			tab = 0;
			ap = strsep(&buf, " ");
			if (ap == NULL) {
				ap = strsep(&buf, "\t");
				if (ap == NULL) {
					break;
				} else {
					tab = 1;
				}
			}
			r = sscanf(strdup(ap), "%d.%d.%d.%d", &ip0, &ip1, &ip2, &ip3);
#if 0
			if (tab)
				printf("\t%s", ap);
			else if (buf == NULL)
				printf("%s", ap);
			else
				printf("%s ", ap);
#endif
			if (r == 4) {
				isnew = ipfind(ip0, ip1, ip2, ip3);
				if (isnew == NULL)
					ipinsert(ip0, ip1, ip2, ip3);
			}
		}

		free(b);
	}
	ipmapcreate();
	ipdump();
	free(bufin);
	if (close(fin) == -1)
		err(EXIT_FAILURE, "Couldn't close input descriptor");
	exit(EXIT_SUCCESS);
}
